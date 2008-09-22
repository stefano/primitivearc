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

   .sub .name :multi()
      P0 = new 'Integer'
      P0 = 0
      .return (P0)
   .end

   .sub .name :multi(PMC, PMC, PMC)
      .param pmc args :slurpy
      
      P0 = new 'Integer'
      P1 = new 'Iterator', args
      P0 = shift P1
loop:
      unless P1 goto end
      P2 = shift P1
      P0 = .name(P0, P2)
      goto loop
end:
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
