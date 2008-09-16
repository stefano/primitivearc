.HLL 'Arc', ''

.namespace [ ]

.sub _types_init :anon :init :load

   ## Cons cell
   
   P0 = subclass 'Array', 'Cons'
   
   ## Symbol 

   P0 = subclass 'Array', 'Symbol'

   ## Nil & T

   P0 = newclass 'Nil'
   P1 = new 'Nil'
   set_hll_global 'nil', P1
   
   P0 = newclass 'T'
   P1 = new 'T'
   set_hll_global 't', P1

   ## Annotated

   P0 = subclass 'Array', 'Tagged'
   
   .return ()
.end

.namespace ['Cons']

.sub __get_string :method
   .local string str
      
   str = "("
   S0 = self[0]
   str .= S0
   P0 = self # P0 holds current cons cell
   I0 = typeof self # cons type
   P2 = get_hll_global 'nil'
cdr_to_str:
   P1 = P0[1]
   I3 = issame P1, P2
   if I3 goto end # check if the list is finished
   I1 = typeof P0[1] # type of the cdr
   if I0 == I1 goto to_list # is it another cons?
   str .= " . "
   S0 = P0[1]
   str .= S0 # add the non-cons object and finish
   goto end
to_list:
   str .= " "
   P0 = P0[1] # advance to next cons cell
   S0 = P0[0]
   str .= S0 # add the car
   goto cdr_to_str
end:
   str .= ")"   

   .return (str)
.end

.namespace ['Symbol']

.sub __get_string :method
   S0 = self[0]
   .return (S0)
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
   S0 = "#3(tagged "
   S1 = self[0]
   S0 .= S1
   S0 .= " "
   S1 = self[1]
   S0 .= S1
   S0 .= ")"
   .return (S0)
.end

## functions accessible to the user

.namespace [ ]

.sub cons
   .param pmc car
   .param pmc cdr

   P0 = new 'Cons'
   P0 = 2
   P0[0] = car
   P0[1] = cdr

   .return (P0)
.end

.sub car
   .param pmc cell
   P0 = cell[0]
   .return (P0)
.end

.sub cdr
   .param pmc cell
   P0 = cell[1]
   .return (P0)
.end

.sub list
   .param pmc elems :slurpy

   .local pmc res
   .local pmc iter
   res = find_global 'nil'
   iter = new 'Iterator', elems

start:	
   unless iter goto end
   P0 = shift iter
   res = cons(P0, res)
   goto start
   
end:	
   .return (res)
.end

## there is no plist in Arc...
.sub plist
   .param pmc sym
   P0 = sym[1]
   .return (P0)
.end

.sub annotate
   .param pmc type
   .param pmc rep

   P0 = new 'Tagged'
   P0 = 2
   P0[0] = type
   P0[1] = rep

   .return (P0)
.end

.sub rep
   .param pmc annotation
   P0 = annotation[1]
   .return (P0)
.end
