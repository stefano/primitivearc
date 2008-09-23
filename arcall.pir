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
   .param pmc pos
   .local pmc nil

   I0 = pos
   if I0 < 0 goto neg_index   
   nil = get_hll_global 'nil'
loop:
   I1 = issame cell, nil
   if I1 goto too_large
   if I0 == 0 goto end
   cell = cdr(cell)
   I0 -= 1
   goto loop
end:
   P0 = car(cell)
   .return (P0)
neg_index:
   .return 'err'("Negative index!")
too_large:
   .return 'err'("Index too large!")
.end

.sub arcall :multi(String)
   .param pmc str
   .param pmc pos
   P0 = new 'String'
   S0 = str[pos]
   P0 = S0
   .return (P0)
.end

##.sub arcall :multi(Symbol)
##   .param pmc sym
## do stuff here
##   .return ()
##.end

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
