.HLL 'Arc', ''

## Dispatch function call on the type of the object
## in function position (1st arg)

## simple function call
## ?? should break in arcall0 arcall1 arcall2 ... arcallany   ??
## ?? to avoid consing rest args (slurpy in the Parrot world) ??
.sub arcall :multi(Sub)
   .param pmc fn
   .param pmc args :slurpy
   .return fn(args :flat)
.end

.sub arcall :multi(MultiSub)
   .param pmc fn
   .param pmc args :slurpy
   .return fn(args :flat)
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
   if_null P0, ret_nil # not found
   .return (P0)
ret_nil:	
   P0 = get_hll_global 'nil'
   .return (P0)
.end
