.HLL 'Arc'

.namespace [ ]

.sub '_types_init' :anon :init :load

	 ## Cons cell
   $P0 = subclass 'ArcCons', 'Cons'

   ## Nil & T

   $P0 = new 'ArcNil'
   set_hll_global 'nil', $P0
   
   $P0 = new 'ArcT'
   set_hll_global 't', $P0

   ## Annotated

   $P0 = subclass 'Array', 'Tagged'

	 ## hash
	 $P0 = subclass 'Hash', 'ArcHash'
	 
   ## I/O ports

   $P0 = newclass 'Inport'
   addattribute $P0, 'stream'

   ## default input port
   $P0 = new 'Inport'
   $P1 = getstdin
   setattribute $P0, 'stream', $P1
   set_hll_global 'stdin*', $P0
   
   $P0 = newclass 'Outport'
   addattribute $P0, 'stream'

   ## default output port
   $P0 = new 'Outport'
   $P1 = getstdout
   setattribute $P0, 'stream', $P1
   set_hll_global 'stdout*', $P0

   ## default error port
   $P0 = new 'Outport'
   $P1 = getstderr
   setattribute $P0, 'stream', $P1
   set_hll_global 'stderr*', $P0

	 
   $P0 = newclass 'Eof'

   $P0 = newclass 'ArcSocket'
	 addattribute $P0, 'stream' 

   ## threading

   $P0 = subclass 'ParrotThread', 'Thread'
   
   .return ()
.end

.namespace ['ArcHash']

.sub 'name' :vtable
	 .return ("hash")
.end

.sub 'get_bool' :vtable :method
	 .return (1)
.end

.sub 'pr_repr' :method
	 .return ("#hash()")
.end

.sub 'to_string' :method
	 .return ("#hash()")
.end

.namespace ['Cons']

.sub 'name' :vtable :method
	 .return ("cons")
.end

.macro cons_string_methods(meth)

	 .sub .meth :method
			.local string str
			.local pmc nil
			
			str = "("
			$P0 = self.'car'()
			$S0 = $P0..meth()
			str .= $S0
			$P0 = self # $P0 holds current cons cell
			nil = get_hll_global 'nil'
cdr_to_str:
			$P1 = $P0.'cdr'()
			$I3 = issame $P1, nil
			if $I3 goto end # check if the list is finished
			$S1 = typeof $P1 # type of the cdr
			if $S1 == 'cons' goto to_list # is it another cons?
			str .= " . "
			$P2 = $P0.'cdr'()
			$S0 = $P2..meth()
			str .= $S0 # add the non-cons object and finish
			goto end
to_list:
			str .= " "
			$P0 = $P0.'cdr'() # advance to next cons cell
			$P2 = $P0.'car'()
			$S0 = $P2..meth()
			str .= $S0 # add the car
			goto cdr_to_str
end:
			str .= ")"   
			
			.return (str)
	 .end
.endm

.cons_string_methods('to_string')
.cons_string_methods('pr_repr')

.namespace ['Tagged']

.macro tagged_string_methods(meth)
	 .sub .meth :method
			$S0 = "#3(tagged "
			$P0 = self[0]
			$S1 = $P0..meth()
			$S0 .= $S1
			$S0 .= " "
			$P0 = self[1]
			$S1 = $P0..meth()
			$S0 .= $S1
			$S0 .= ")"
			.return ($S0)
	 .end
.endm

.tagged_string_methods('to_string')
.tagged_string_methods('pr_repr')

.namespace ['Inport']

.sub 'pr_repr' :method
   .return ("#<input port>")
.end

.sub 'to_string' :method
   .return ("#<input port>")
.end

## compatibility with ReadStream

.sub 'is_eof' :method
   $P0 = getattribute self, 'stream'
   $I0 = $P0.'eof'()
   if $I0 goto true
   .return (0)
true:
   .return (1)
.end

.sub 'peek1' :method
   $P0 = getattribute self, 'stream'
   $S0 = peek $P0
   $I0 = $P0.'eof'()
   if $I0 goto end
   .return ($S0)
end:
   $P0 = get_hll_global 'nil'
   .return ($P0)
.end

.sub 'get1' :method
   $P0 = getattribute self, 'stream'
   $S0 = $P0.'read'(1)
   $I0 = $P0.'eof'()
   if $I0 goto end
   .return ($S0)
end:
   $P0 = get_hll_global 'nil'
   .return ($P0)
.end

.namespace ['Outport']

.sub 'pr_repr' :method
   .return ("#<output port>")
.end

.sub 'to_string' :method
   .return ("#<output port>")
.end

.namespace ['Eof']

.sub 'name' :vtable :method
	 .return ("eof")
.end

.sub 'get_bool' :vtable :method
	 .return (1)
.end

.sub 'pr_repr' :method
   .return ("#<eof>")
.end

.sub 'to_string' :method
   .return ("#<eof>")
.end

.namespace ['ArcSocket']

.sub 'name' :vtable :method
	 .return ("socket")
.end

.sub 'pr_repr' :method
   .return ("#<socket>")
.end

.sub 'to_string' :method
   .return ("#<socket>")
.end

.namespace ['Thread']

.sub 'pr_repr' :method
   .return ("#<thread>")
.end

.sub 'to_string' :method
   .return ("#<thread>")
.end

## functions accessible to the user

.namespace [ ]

.sub 'cons'
   .param pmc car
   .param pmc cdr

	 $P0 = new 'Cons'
	 $P0.'scar'(car)
	 $P0.'scdr'(cdr)
	 	 
   .return ($P0)
.end

.sub 'car'
   .param pmc cell
 	 $P0 = cell.'car'()
	 .return ($P0)
.end

.sub 'scar'
   .param pmc cell
   .param pmc val
	 cell.'scar'(val)
   .return (val)
.end

.sub 'cdr'
   .param pmc cell
	 $P0 = cell.'cdr'()
	 .return ($P0)
.end

.sub 'scdr'
   .param pmc cell
   .param pmc val
	 cell.'scdr'(val)
   .return (val)
.end

.sub 'list'
   .param pmc elems :slurpy

   .local pmc res
   .local pmc last
   .local pmc iter
   .local pmc nil
   nil = get_hll_global 'nil'
   last = nil
   res = nil
   iter = elems

start:	
   unless iter goto end
   $P0 = shift iter
   $I0 = issame last, nil
   if $I0 goto first
   $P0 = cons($P0, nil)
   scdr(last, $P0)
   last = $P0
   goto start
first:
   last = cons($P0, nil)
   res = last
   goto start
end:	
   .return (res)
.end

.sub '_list_to_array'
   .param pmc lst
   .local pmc res
   .local pmc nil
   
   res = new 'ResizablePMCArray'
   nil = get_hll_global 'nil'
loop:
   $I0 = issame lst, nil
   if $I0 goto end
   $P0 = car(lst)
   push res, $P0
   lst = cdr(lst)
   goto loop
end:
   .return (res)
.end

## there is no plist in Arc...
.sub 'plist'
   .param pmc sym
   $P0 = sym[1]
   .return ($P0)
.end

.sub 'annotate'
   .param pmc type
   .param pmc rep

   $P0 = new 'Tagged'
   $P0 = 2
   $P0[0] = type
   $P0[1] = rep

   .return ($P0)
.end

.sub 'rep'
   .param pmc annotation
   $P0 = annotation[1]
   .return ($P0)
.end

.sub 'table'
   $P0 = new 'ArcHash'
   .return ($P0)
.end

.sub 'sref' :multi(ArcHash)
   .param pmc h
   .param pmc val
   .param pmc key

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
   h[$S0] = val

   .return (val)
.end

.sub 'sref' :multi(ArcStr)
   .param pmc str
   .param pmc val
   .param pmc ind

   $S0 = typeof val
   unless $S0 == 'char' goto type_err
   $S0 = typeof ind
   unless $S0 == 'int' goto type_err2
   $S0 = val.'pr_repr'()
   str[ind] = $S0
   .return (val)
type_err:
   .tailcall 'err'("Wrong type passed as value to sref (string)")
type_err2:
   .tailcall 'err'("Wrong type passed as index to sref (string)")
.end

.sub 'sref' :multi(Cons)
   .param pmc cell
   .param pmc val
   .param pmc ind

   $S0 = typeof ind
   unless $S0 == 'int' goto type_err
   
   .local pmc nil
   $I0 = ind
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
   .tailcall scar(cell, val)
neg_index:
   .tailcall 'err'("Negative index!")
too_large:
   .tailcall 'err'("Index too large!")   
type_err:
   .tailcall 'err'("Wrong type passed as index to sref (cons)")
.end

# .sub 'sref' :multi(_, _, _)
# 	 .param pmc x
# 	 .param pmc y
# 	 .param pmc z

# 	 $S0 = "Can't sref "
# 	 $S1 = x.'to_string'()
# 	 $S0 .= $S1
# 	 .tailcall 'err'($S0)
# .end

.sub 'type'
   .param pmc what
   $S0 = typeof what
   if $S0 == 'Tagged' goto tagged
   .tailcall 'intern'($S0)
tagged:
   $P0 = what[0]
   .return ($P0)
.end

## coercion

.sub 'char->int'
	 .param pmc char

	 $S0 = char.'pr_repr'()
	 $I0 = ord $S0

	 .return ($I0)
.end

.sub 'int->char'
	 .param pmc i

	 $I0 = i
	 $S0 = chr $I0
	 $P0 = new 'ArcChar'
	 $P0 = $S0

	 .return ($P0)
.end

