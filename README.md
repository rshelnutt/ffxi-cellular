# ffxi-cellular

-------------------------------------------
Cellular v1.0.0 -- Blace of Ifrit 
-------------------------------------------
WIP prototype VoidWatch bulk cell purchaser for Windower 4

PLEASE NOTE:
- Currently only works in Southern Sandoria. Other VW NPCs will be added soon
- Only Rubicund and Cobalt cells can currently be purchased. I may expand to support the others, but those rarely see use anymore.
- Inventory space validation will be added later. For the time being, make sure you have plenty of room to support the number of purchased cells/cell stacks.
- Refactor some of the assignment loops, clean-up.

Feel free to submit a PR for any of the above.

[Disclaimer]
This script is a wip and is provided as-is.
This is an automated purchasing tool that uses packet injection; use at your own risk (however minor it may be).
     
```lua //vwc buy(b) {Rubicund(r), Cobalt(c)} {number}```  
```lua //vwc b c 17```  
```lua //vwc buy Rubicund 42```
