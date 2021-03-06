.HLL 'Arc'

## Dispatch function call on the type of the object
## in function position (1st arg)

## simple function call
## ?? should break in arcall0 arcall1 arcall2 ... arcallany   ??
## ?? to avoid consing rest args ??
.macro arcallwith(type)
	 .sub arcall :multi(.type)
			.param pmc fn
			.param pmc args :slurpy
			.tailcall fn(args :flat)
	 .end
.endm

.arcallwith(Sub)
.arcallwith(MultiSub)

.sub arcall :multi(Cons)
	 .param pmc fn
	 .param pmc args :slurpy
	 .tailcall arcall1(fn, args :flat)
.end

.sub arcall1 :multi(Sub)
   .param pmc fn
   .param pmc arg
   .tailcall fn(arg)
.end

.sub arcall1 :multi(MultiSub)
   .param pmc fn
   .param pmc arg
   .tailcall fn(arg)
.end

.sub arcall2 :multi(Sub)
   .param pmc fn
   .param pmc arg1
   .param pmc arg2
   .tailcall fn(arg1, arg2)
.end

.sub arcall2 :multi(MultiSub)
   .param pmc fn
   .param pmc arg1
   .param pmc arg2
   .tailcall fn(arg1, arg2)
.end

.sub arcall1 :multi(Continuation)
   .param pmc cc
   .param pmc arg1

   .tailcall cc(arg1)
.end

.sub arcall1 :multi(Cons)
   .param pmc cell
   .param pmc pos
   .local pmc nil

   $I0 = pos
   if $I0 < 0 goto neg_index   
   nil = get_hll_global 'nil'
loop:
   $I1 = issame cell, nil
   if $I1 goto too_large
   if $I0 == 0 goto end
   cell = cdr(cell)
   $I0 -= 1
   goto loop
end:
   $P0 = car(cell)
   .return ($P0)
neg_index:
   .tailcall 'err'("Negative index!")
too_large:
   .tailcall 'err'("Index too large!")
.end

.sub arcall1 :multi(ArcNil)
	 .param pmc the_nil
	 .param pmc pos

	 .return (the_nil)
.end

.sub arcall1 :multi(ArcStr)
   .param pmc str
   .param pmc pos
   $P0 = new 'ArcChar'
   $S0 = str[pos]
   $P0 = $S0
   .return ($P0)
.end

##.sub arcall :multi(Symbol)
##   .param pmc sym
## do stuff here
##   .tailcall ()
##.end

.sub arcall1 :multi(Hash)
   .param pmc table
   .param pmc key
   ## !! Parrot transforms key in a string to make the hash
   ## !! this means, for example, that a string containing "(1 2)"
   ## !! is considered the same as the list (1 2)
	 $S0 = typeof key
	 unless $S0 == 'string' goto tostring
	 $S0 = "\""
	 $S1 = key
	 $S0 .= $S1
	 $S0 .= "\""
	 goto go
tostring:	
	 $S0 = key.'to_string'()
go:			
   $P0 = table[$S0]
   if_null $P0, ret_nil # not found
   $P0 = $P0[1] # 0 -> key, 1 -> val
   .return ($P0)
ret_nil:	
   $P0 = get_hll_global 'nil'
   .return ($P0)
.end

## catch everything
.macro call_error(name, arg_list)
   .sub .name :multi(PMC)
      .param pmc what
      .arg_list
      
      $P0 = new 'String'
      $P0 = "Can't call a "
      $S0 = typeof what
      $P0 .= $S0
			$P0 .= ": "
			$S0 = what.'to_string'()
			$P0 .= $S0
      .tailcall 'err'($P0)
   .end
.endm

.call_error('arcall1', {.param pmc arg1})
.call_error('arcall2', {.param pmc arg1
                      .param pmc arg2})
.call_error('arcall', {.param pmc args :slurpy})
