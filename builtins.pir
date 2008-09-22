## builtin functions

.HLL 'Arc', ''

.sub err
   .param pmc what
   P0 = new 'String'
   P0 = "Error: "
   P0 .= what
   die P0
   .return (P0)
.end

.sub len :multi(Cons)
   .param pmc lst

   .local pmc nil
   nil = get_hll_global 'nil'
   I0 = 0
loop:
   I1 = issame lst, nil
   if I1 goto end
   lst = cdr(lst)
   I0 += 1
   goto loop
end:
   P0 = new 'Integer'
   P0 = I0
   .return (P0)
.end

.sub len :multi(Hash)
   .param pmc h

   I0 = h
   P0 = new 'Integer'
   P0 = I0
   .return (P0)
.end

.sub len :multi(String)
   .param pmc s

   S0 = s
   I0 = length S0
   P0 = new 'Integer'
   P0 = I0
   .return (P0)
.end
