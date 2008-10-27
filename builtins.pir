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

## arithmethic

.macro defmathop(name, op)

   ## default sub called if the others fail to match
   .sub .name :multi()
      .param pmc args :slurpy
      
      P0 = new 'Integer'
      P1 = new 'Iterator', args
      unless P1 goto zero_args
      P0 = shift P1
loop:
      unless P1 goto end
      P2 = shift P1
      P0 = .name(P0, P2)
      goto loop
end:
      .return (P0)
zero_args:
      P0 = new 'Integer'
      P0 = 0
      .return (P0)
   .end

   .sub .name :multi(Integer, Integer)
      .param pmc i1
      .param pmc i2
      
      P0 = new 'Integer'
      P0 = i1 .op i2
      .return (P0)
   .end

   
   .sub .name :multi(Integer, Float)
      .param pmc i1
      .param pmc i2
      
      P0 = new 'Float'
      P0 = i1 .op i2

      .return (P0)
   .end

   .sub .name :multi(Float, Integer)
      .param pmc i1
      .param pmc i2
      
      P0 = new 'Float'
      P0 = i1 .op i2

      .return (P0)
   .end

   .sub .name  :multi(Float, Float)
      .param pmc i1
      .param pmc i2
      
      P0 = new 'Float'
      P0 = i1 .op i2

      .return (P0)
   .end

   .sub .name :multi(PMC)
     .param pmc i
     P0 = new 'Integer'
     P0 = 0
     P0 = P0 .op i
     .return (P0)
  .end


.endm

.defmathop('+', +)
.defmathop('-', -)
.defmathop('*', *)
.defmathop('/', /)

.sub mod
   .param pmc a
   .param pmc b
   P0 = new 'Integer'
   P0 = a / b
   I0 = P0
   P0 = I0
   .return (P0)
.end

.sub expt
   .param pmc a
   .param pmc b
   P0 = new 'Integer'
   P0 = pow a, b
   .return (P0)
.end

.sub 'sqrt'
   .param pmc a
   N0 = a
   N0 = sqrt N0
   P0 = new 'Float'
   P0 = N0
   .return (P0)   
.end

.sub is :multi()
   .param pmc args :slurpy
   .local pmc nil
   nil = get_hll_global 'nil'
   P0 = new 'Iterator', args
   unless P0 goto error
   P1 = shift P0
   P2 = shift P0
loop:
   P3 = is(P1, P2)
   I0 = issame P3, nil
   if I0 goto no
   unless P0 goto yes
   P1 = P2
   P2 = shift P0
   goto loop
yes:
   P0 = get_hll_global 't'
   .return (P0)
no:
   .return (nil)
error:
   .return 'err'("is needs at least one argument!")
.end

.sub is :multi(PMC)
   .param pmc a
   P0 = get_hll_global 't'
   .return (P0)
.end

.sub is :multi(PMC, PMC)
   .param pmc a
   .param pmc b
   .local int int_type
   .local int float_type
   .local int str_type

   int_type = find_type 'Integer'
   float_type = find_type 'Float'
   str_type = find_type 'String'
   
   I0 = typeof a
   I1 = typeof b
   unless I0 == I1 goto no
   if I0 == int_type goto value_compare
   if I0 == float_type goto value_compare
   if I0 == str_type goto value_compare
   
adress_compare:
   I0 = issame a, b
   if I0 goto yes
   goto no
value_compare:
   if a == b goto yes
no:
   P0 = get_hll_global 'nil'
   .return (P0)
yes:
   P0 = get_hll_global 't'
   .return (P0)
.end

.sub '+' :multi(Cons, Cons)
   .param pmc a
   .param pmc b
   .local pmc nil
   
   nil = get_hll_global 'nil'
   P0 = nil
loop:
   I0 = issame a, nil
   if I0 goto copy_b
   P1 = car(a)
   P0 = cons(P1, P0)
   a = cdr(a)
   goto loop
copy_b:
   I0 = issame b, nil
   if I0 goto end
   P1 = car(b)
   P0 = cons(P1, P0)
   b = cdr(b)
   goto copy_b
end:
   .return (P0)
.end

.sub '+' :multi(String, String)
   .param pmc s1
   .param pmc s2

   S0 = s1
   S1 = s2
   S0 .= S1

   P0 = new 'String'
   P0 = S0
   .return (P0)
.end

.include 'interpinfo.pasm' # for .INTERPINFO_CURRENT_CONT

.sub 'ccc'
   .param pmc f

   interpinfo P0, .INTERPINFO_CURRENT_CONT

   .return f(P0)
.end

.sub 'prn'
   .param pmc what

   say what

   .return (what)
.end

