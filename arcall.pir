.HLL 'Arc', ''

## Dispatch function call on the type of the object
## in function position (1st arg)

## simple function call
## ?? should break in arcall0 arcall1 arcall2 ... arcallany   ??
## ?? to avoid consing rest args (slurpy in the Parrot world) ??
.sub arcall :multi(Sub)
   .param pmc fn
   ## do stuff here
   .return ()
.end

.sub arcall :multi(Cons)
   .param pmc cell
   ## do stuff here
   .return ()
.end

.sub arcall :multi(String)
   .param pmc str
   ## do stuff here
   .return ()
.end

.sub arcall :multi(Symbol)
   .param pmc sym
   ## do stuff here
   .return ()
.end

.sub arcall :multi(Hash)
   .param pmc table
   .param pmc key
   P0 = table[key]
   .return (P0)
.end
