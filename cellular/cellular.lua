--[[
Cellular v1.0.0

Copyright © 2021 Blace
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
* Neither the name of craft nor the names of its contributors may be
used to endorse or promote products derived from this software without
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL BLACE BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

_addon.name     = 'cellular'
_addon.author   = 'Blace'
_addon.version  = '1.0.0'
_addon.commands = {'vwc'}

require('coroutine')
require('queues')
require('logger')

local help_text = [[
-----------------------------------------------------------
Cellular v1.0.0 -- Author: Blace of Ifrit (gh:rshelnutt)
-----------------------------------------------------------
    Submit an issue on GitHub if you have any problems. 
    This script is a wip and is provided as-is.
    This is an automated purchasing tool that uses packet injection;
    use at your own risk (however minor it may be).
     
    //vwc buy(b) {Rubicund(r), Cobalt(c)} {number}
    //vwc b c 17
    //vwc buy Rubicund 42
]]

local packets = require('packets')
local queue = Q{}
local handlers = {}
local busy = false
local cellType = nil
local conditions = {
    buy = false,
}

local vw_npcs = {
    {name = "Voidwatch Officer", id = 17719635, zone = 230, menu = 963},
}

local function validate(npcs)
    zone = windower.ffxi.get_info()['zone']
    local valid = false
    for _, npc in pairs(npcs) do
        if zone == npc.zone then
            valid = true
            local mob = windower.ffxi.get_mob_by_id(npc.id)
            if mob then
                if (math.sqrt(mob.distance) < 6) then
                    return mob, npc
                end
            end
        end
    end
    if valid then
        error("You are too far from the Voidwatch NPC.")
    end
end

local function exit_npc()
    local mob, npc = validate(vw_npcs)
    if npc then
        local p = packets.new('outgoing', 0x5b, {
            ["Target"] = mob.id,
            ["Option Index"] = 0,
            ["_unknown1"] = 16384,
            ["Target Index"] = mob.index,
            ["Automated Message"] = false,
            ["_unknown2"] = 0,
            ["Zone"] = zone,
            ["Menu ID"] = npc.menu,
        })
        packets.inject(p)
    end
    conditions['buy'] = false
end

local function get_cells(id, data)
    if (id == 0x34) and conditions['buy'] then
        local mob, npc = validate(vw_npcs)

        if npc then
            local p = packets.new('outgoing', 0x5b, {
                ["Target"] = mob.id,
                ["Option Index"] = 2,
                ["_unknown1"] = cellType,
                ["Target Index"] = mob.index,
                ["Automated Message"] = false,
                ["Zone"] = zone,
                ["Menu ID"] = npc.menu,
            })
            packets.inject(p)
        end

        cellType = nil

        exit_npc()
        return true
    end
end

local function poke_npc()
    if windower.ffxi.get_player().status ~= 0 then
        return "You can't make that purchase at the moment."
    end

    local mob, npc = validate(vw_npcs)
    if npc then
        conditions['buy'] = true
        local p = packets.new('outgoing', 0x01a, {
            ["Target"] = mob.id,
            ["Target Index"] = mob.index,
            ["Category"] = 0,
            ["Param"] = 0,
            ["_unknown1"] = 0,
        })
        packets.inject(p)
    end
end

local function issue_purchase(item)
    if     (item == "Rubicundx12") then
        cellType = 770
    elseif (item == "Rubicundx9") then
        cellType = 578
    elseif (item == "Rubicundx6") then
        cellType = 386
    elseif (item == "Rubicundx3") then
        cellType = 194
    elseif (item == "Rubicundx1") then
        cellType = 66
    elseif (item == "Cobaltx12") then
        cellType = 769
    elseif (item == "Cobaltx9") then
        cellType = 577
    elseif (item == "Cobaltx6") then
        cellType = 385
    elseif (item == "Cobaltx3") then
        cellType = 193
    elseif (item == "Cobaltx1") then
        cellType = 65
    end

    poke_npc()
end

local function check_queue()
    if not queue:empty() then
        local fn, arg = unpack(queue:pop())
        local msg = fn(arg)
        if msg then
            error(msg)
        end
        coroutine.schedule(check_queue, 3)
    else
        busy = false
        notice("Purchase complete!")
    end
end

local function process_queue()
    if not busy then
        busy = true
        coroutine.schedule(check_queue, 0)
    end
end

local function handle_buy(item, count)
    local mob, npc = validate(vw_npcs)
    if npc then
        if conditions['buy'] then
            return "Please wait until your current purchase queue has completed."
        else
            local count = count or 1
            local n = tonumber(count)
            local cellType

            if n == nil then
                return "Invalid count %s":format(count)
            end

            if item == nil then
                return "Invalid cell type provided. Valid types: Rubicund (r), Cobalt (c) "
            end

            if (item == 'Rubicund') or (item == 'rubicund') or (item == 'Cobalt') or (item == 'cobalt') or (item == 'r') or (item == 'c') then
                cellType = item
                local cellText = "cell"
                if tonumber(count) > 1 then
                    cellText = "cells"
                end

                if cellType == "r" or cellType == "rubicund" then
                    cellType = "Rubicund"
                elseif cellType == "c" or cellType == "cobalt" then
                    cellType = "Cobalt"
                end

                notice("!!! DO NOT MOVE !!! - Purchasing %d %s %s from NPC, please wait...":format(count, cellType, cellText))
            else
                return "Invalid cell type: %s":format(item)
            end

            if n > 0 then
                local total = tonumber(count)
                for i = 1, total do
                    local evalItem = nil

                    if total > 0 then
                        if total < 12 then
                            if (9 % total == 0 or total < 9) and 9/total ~= 1 then
                                if (6 % total == 0 or total < 6) and 6/total ~= 1 then
                                    if (3 % total == 0 or total < 3) and 3/total ~= 1 then
                                        total = total  - 1
                                        evalItem = cellType .. "x1"
                                    else
                                        total = total  - 3
                                        evalItem = cellType .. "x3"
                                    end
                                else
                                    total = total  - 6
                                    evalItem = cellType .. "x6"
                                end
                            else
                                total = total  - 9
                                evalItem = cellType .. "x9"
                            end
                        else
                            total = total  - 12
                            evalItem = cellType .. "x12"
                        end

                        local item = {issue_purchase, evalItem}
                        queue:push(item)
                    end
                end
            else
                return "Invalid quantity provided, must be a value greater than 0."
            end

            total = 0

            process_queue()
        end
    end
end

local function handle_help()
    windower.add_to_chat(100, help_text)
end

handlers['?'] = handle_help
handlers['h'] = handle_help
handlers['help'] = handle_help
handlers['b'] = handle_buy
handlers['buy'] = handle_buy

local function handle_command(cmd, ...)
    local cmd = cmd or 'help'
    if handlers[cmd] then
        local msg = handlers[cmd](unpack({...}))
        if msg then
            error(msg)
        end
    else
        error("Unknown command %s":format(cmd))
    end
end

windower.register_event('addon command', handle_command)
windower.register_event('incoming chunk', get_cells)
