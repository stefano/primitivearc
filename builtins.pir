## builtin functions

.HLL 'Arc', ''

.include 'interpinfo.pasm' # for .INTERPINFO_CURRENT_CONT

.sub err
   .param pmc what
   .local string msg
   msg = "\nWithin "
   P0 = new 'String'
   P0 = "Error: "
   P0 .= what
   ## construct the backtrace
   P1 = interpinfo .INTERPINFO_CURRENT_CONT
loop:
   P0 .= msg
   msg = "\nCalled by "
   S0 = P1.'caller'()
   P0 .= S0
   P1 = P1.'continuation'()
   if P1 goto loop
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

.sub len :multi(Nil)
   .param pmc thenil
   P0 = new 'Integer'
   P0 = 0
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

## copy a list
## return head of the list and the last cons cell
.sub 'copy'
   .param pmc l
   .local pmc nil
   .local pmc res
   .local pmc last

   nil = find_global 'nil'
   last = nil
   res = nil
start:
   I0 = issame nil, l
   if I0 goto end
   P0 = car(l)
   l = cdr(l)
   I0 = issame last, nil
   if I0 goto first
   P0 = cons(P0, nil)
   scdr(last, P0)
   last = P0
   goto start
first:
   last = cons(P0, nil)
   res = last
   goto start
end:	
   .return (res, last)
.end

.sub '+' :multi(Nil, Cons)
   .param pmc a
   .param pmc b
   
   .return 'copy'(b)
.end

.sub '+' :multi(Cons, Nil)
   .param pmc a
   .param pmc b
   
   .return 'copy'(a)
.end

.sub '+' :multi(Cons, Cons)
   .param pmc a
   .param pmc b
   .local pmc nil

   (P0, P1) = 'copy'(a)
   P2 = 'copy'(b)
   scdr(P1, P2)
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

.sub 'eval'
   .param pmc what
   
   P1 = _tl_compile(what)
   P0 = compreg 'PIR'
   P1 = P0(P1)
   P1()
   P0 = get_hll_global '***' # !! I don't like this
   .return (P0)
.end

## I/O

.sub 'stdin'
   P0 = getstdin
   P1 = new 'Inport'
   setattribute P1, 'stream', P0
   .return (P1)
.end

.sub 'stdout'
   P0 = getstdout
   P1 = new 'Outport'
   setattribute P1, 'stream', P0
   .return (P1)
.end

.sub 'stderr'
   P0 = getstderr
   P1 = new 'Outport'
   setattribute P1, 'stream', P0
   .return (P1)
.end

.sub '_open_file'
   .param pmc fname
   .param pmc io_obj
   .param string direction

   S0 = fname
   P0 = open S0, direction
   unless P0 goto error
   setattribute io_obj, 'stream', P0
   .return (io_obj)
error:
   S0 = "Can't open file: "
   S1 = fname
   S0 .= S1
   'err'(S0)
.end

.sub 'infile'
   .param pmc fname
   P0 = new 'Inport'
   .return '_open_file'(fname, P0, '<')
.end

.sub 'outfile'
   .param pmc fname
   P0 = new 'Outport'
   .return '_open_file'(fname, P0, '>')
.end

.sub 'inside'
   .param pmc str
   P0 = new 'ReadStream'
   P0.'input'(str)
   .return (P0)
.end

.sub 'pipe-from'
   .param pmc cmd
   P0 = new 'Inport'
   .return '_open_file'(cmd, P0, '-|')
.end

## not in Arc2
.sub 'pipe-to'
   .param pmc cmd
   P0 = new 'Outport'
   .return '_open_file'(cmd, P0, '|-')
.end

.sub 'close'
   .param pmc port
   
   P0 = getattribute port, 'stream'   
   close P0
   P0 = get_hll_global 'nil'
   .return (P0)
.end

.sub 'readc'
   .param pmc inport
   .return inport.'get1'()
.end
   
.sub 'readb'
   .param pmc inport
   .return 'readc'(inport)
.end

.sub 'peekc'
   .param pmc inport
   .return inport.'peek1'()
.end

.sub 'read'
   .param pmc inport
   .return _read(inport)
.end

## this is actually write-string...
.sub 'writec'
   .param pmc c
   .param pmc outport
   
   P0 = getattribute outport, 'stream'
   S0 = c
   print P0, S0
   
   .return (c)
.end

.sub 'writeb'
   .param pmc c
   .param pmc outport
   .return 'writec'(c, outport)
.end

.sub 'write'
   .param pmc what
   .param pmc outport

   S1 = what # conversion
   S0 = typeof what
   unless S0 == 'String' goto go_on
   S0 = "\""
   S0 .= S1
   S0 .= "\""
   S1 = S0
go_on:
   P0 = getattribute outport, 'stream'
   print P0, S1
   .return (what)
.end

.sub 'disp'
   .param pmc what
   .param pmc outport

   S0 = what # conversion
   P0 = getattribute outport, 'stream'
   print P0, S0
   .return (what)
.end

.sub 'load'
   .param pmc file

   P0 = 'infile'(file)
   P2 = get_hll_global 'nil'
loop:
   P1 = 'read'(P0)
   S0 = typeof P1
   if S0 == 'Eof' goto end
   P2 = 'eval'(P1)
   goto loop
end:
   .return (P2)
.end

.sub 'system'
   .param pmc cmd
   S0 = cmd
   I0 = spawnw S0
   P0 = new 'Integer'
   P0 = I0
   .return (P0)
.end

.sub 'dir'
   .param pmc path
   S0 = path
   P0 = new 'OS'
   P0 = P0.'readdir'(S0)
   .return 'list'(P0 :flat)
.end

.sub 'rmfile'
   .param pmc path
   S0 = path
   P0 = new 'OS'
   push_eh error
   P0.'rm'(path)
   pop_eh
   P0 = get_hll_global 'nil'
   .return (P0)
error:
   .get_results(P0)
   .return 'err'(P0)
.end

.sub 'file-exists'
   .param pmc path
   S0 = path
   I0 = stat S0, 0
   if I0 goto true
   P0 = get_hll_global 'nil'
   .return (P0)
true:
   P0 = get_hll_global 't'
   .return (P0)
.end

.sub 'dir-exists'
   .param pmc path
   S0 = path
   I0 = stat S0, 0
   unless I0 goto false
   I0 = stat S0, 2
   unless I0 goto false
   P0 = get_hll_global 't'
   .return (P0)
false:
   P0 = get_hll_global 'nil'
   .return (P0)
.end

