.HLL 'Arc'

.namespace [ ]

.sub _types_init :anon :init :load

   ## Cons cell
   
   $P0 = subclass 'Array', 'Cons'
   
   ## Symbol 

   $P0 = subclass 'Array', 'Symbol'

   ## Nil & T

   $P0 = newclass 'Nil'
   $P1 = new 'Nil'
   set_hll_global 'nil', $P1
   
   $P0 = newclass 'T'
   $P1 = new 'T'
   set_hll_global 't', $P1

   ## Annotated

   $P0 = subclass 'Array', 'Tagged'

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
   
   $P0 = newclass 'Eof'

   $P0 = newclass 'Socketport'
   addattribute $P0, 'fd'

   ## threading

   $P0 = subclass 'ParrotThread', 'Thread'
   
   .return ()
.end

.namespace ['Cons']

.sub __get_string :method
   .local string str
      
   str = "("
   $S0 = self[0]
   str .= $S0
   $P0 = self # $P0 holds current cons cell
   $P2 = get_hll_global 'nil'
cdr_to_str:
   $P1 = $P0[1]
   $I3 = issame $P1, $P2
   if $I3 goto end # check if the list is finished
   $S1 = typeof $P1 # type of the cdr
   if $S1 == 'Cons' goto to_list # is it another cons?
   str .= " . "
   $S0 = $P0[1]
   str .= $S0 # add the non-cons object and finish
   goto end
to_list:
   str .= " "
   $P0 = $P0[1] # advance to next cons cell
   $S0 = $P0[0]
   str .= $S0 # add the car
   goto cdr_to_str
end:
   str .= ")"   

   .return (str)
.end

.namespace ['Symbol']

.sub __get_string :method
   $S0 = self[0]
   .return ($S0)
.end

.namespace ['Nil']

.sub __get_string :method
   .return("nil")
.end

.namespace ['T']

.sub __get_string :method
   .return("t")
.end

.namespace ['Tagged']

.sub __get_string :method
   $S0 = "#3(tagged "
   $S1 = self[0]
   $S0 .= $S1
   $S0 .= " "
   $S1 = self[1]
   $S0 .= $S1
   $S0 .= ")"
   .return ($S0)
.end

.namespace ['Inport']

.sub __get_string :method
   .return ("#<input port>")
.end

## compatibility with ReadStream

.sub is_eof :method
   $P0 = getattribute self, 'stream'
   $I0 = $P0.'eof'()
   if $I0 goto true
   .return (0)
true:
   .return (1)
.end

.sub peek1 :method
   $P0 = getattribute self, 'stream'
   $S0 = peek $P0
   $I0 = $P0.'eof'()
   if $I0 goto end
   .return ($S0)
end:
   $P0 = get_hll_global 'nil'
   .return ($P0)
.end

.sub get1 :method
   $P0 = getattribute self, 'stream'
   $S0 = read $P0, 1
   $I0 = $P0.'eof'()
   if $I0 goto end
   .return ($S0)
end:
   $P0 = get_hll_global 'nil'
   .return ($P0)
.end

.namespace ['Outport']

.sub __get_string :method
   .return ("#<output port>")
.end

.namespace ['Eof']

.sub __get_string :method
   .return ("#<eof>")
.end

.namespace ['Socketport']

.sub __get_string :method
   .return ("#<socket>")
.end

.namespace ['Thread']

.sub __get_string :method
   .return ("#<thread>")
.end

## functions accessible to the user

.namespace [ ]

.sub cons
   .param pmc car
   .param pmc cdr

   $P0 = new 'Cons'
   $P0 = 2
   $P0[0] = car
   $P0[1] = cdr

   .return ($P0)
.end

.sub car
   .param pmc cell
   $P0 = get_hll_global 'nil'
   $I0 = issame $P0, cell
   if $I0 goto final
   $P0 = cell[0]
final:
   .return ($P0)
.end

.sub scar
   .param pmc cell
   .param pmc val
   cell[0] = val
   .return (val)
.end

.sub cdr
   .param pmc cell
   $P0 = get_hll_global 'nil'
   $I0 = issame $P0, cell
   if $I0 goto final
   $P0 = cell[1]
final:
   .return ($P0)
.end

.sub scdr
   .param pmc cell
   .param pmc val
   cell[1] = val
   .return (val)
.end

.sub list
   .param pmc elems :slurpy

   .local pmc res
   .local pmc last
   .local pmc iter
   .local pmc nil
   nil = find_global 'nil'
   last = nil
   res = nil
   iter = new 'Iterator', elems

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

.sub _list_to_array
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
.sub plist
   .param pmc sym
   $P0 = sym[1]
   .return ($P0)
.end

.sub annotate
   .param pmc type
   .param pmc rep

   $P0 = new 'Tagged'
   $P0 = 2
   $P0[0] = type
   $P0[1] = rep

   .return ($P0)
.end

.sub rep
   .param pmc annotation
   $P0 = annotation[1]
   .return ($P0)
.end

.sub table
   $P0 = new 'Hash'
   .return ($P0)
.end

.sub sref :multi(Hash)
   .param pmc h
   .param pmc val
   .param pmc key

   h[key] = val

   .return (val)
.end

.sub sref :multi(String)
   .param pmc str
   .param pmc val
   .param pmc ind

   $S0 = typeof val
   unless $S0 == 'String' goto type_err
   $S0 = typeof ind
   unless $S0 == 'Integer' goto type_err2
   $S0 = val
   str[ind] = $S0
   .return (val)
type_err:
   .tailcall 'err'("Wrong type passed as value to sref (string)")
type_err2:
   .tailcall 'err'("Wrong type passed as index to sref (string)")
.end

.sub sref :multi(Cons)
   .param pmc cell
   .param pmc val
   .param pmc ind
   
   $S0 = typeof ind
   unless $S0 == 'Integer' goto type_err
   
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

.sub 'type'
   .param pmc what
   $S0 = typeof what
   if $S0 == 'Tagged' goto tagged
   $S0 = downcase $S0
   .tailcall 'intern'($S0)
tagged:
   $P0 = what[0]
   .return ($P0)
.end
