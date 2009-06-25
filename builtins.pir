## builtin functions

.HLL 'Arc'

.include 'interpinfo.pasm' # for .INTERPINFO_CURRENT_CONT

.sub '_str_err'
   .param pmc what
   .local string msg
   msg = "\nWithin "
   $S0 = "Error: "
   $S1 = what
   $S0 .= $S1
   ## construct the backtrace
   $P1 = interpinfo .INTERPINFO_CURRENT_CONT
   $P1 = $P1.'continuation'() # skip one
loop:
   $S0 .= msg
   msg = "\nCalled by "
   $S1 = $P1.'caller'()
   $S0 .= $S1
   $P1 = $P1.'continuation'()
   if $P1 goto loop
   .return ($S0)
.end

.sub 'err'
   .param pmc what
	 $S0 = _str_err(what)
   $P0 = new 'ArcStr'
	 $P0 = $S0

   die $P0
#	 .return (what)
.end

.sub 'protect'
	 .param pmc during
	 .param pmc after

	 push_eh error
	 $P0 = 'arcall'(during)
	 pop_eh
	 .return ($P0)
error:
	 .local pmc ex
	 .get_results(ex)
	 .tailcall 'arcall'(after)
.end

.sub 'len' :multi(Cons)
   .param pmc lst

   .local pmc nil
   nil = get_hll_global 'nil'
   $I0 = 0
loop:
   $I1 = issame lst, nil
   if $I1 goto end
   lst = cdr(lst)
   $I0 += 1
   goto loop
end:
   .return ($I0)
.end

.sub 'len' :multi(ArcNil)
   .param pmc thenil
   .return (0)
.end

.sub 'len' :multi(Hash)
   .param pmc h
   $I0 = h
   .return ($I0)
.end

.sub 'len' :multi(ArcStr)
   .param string s

   $S0 = s
   $I0 = length $S0
   .return ($I0)
.end

.sub 'len' :multi(_)
	 .param pmc x

	 $S0 = "Can't take len of "
	 $S1 = x.'to_string'()
	 $S0 .= $S1
	 .tailcall 'err'($S0)
.end

## arithmethic

.macro defmathop(name, op)

   ## default sub called if the others fail to match
   .sub .name :multi()
      .param pmc args :slurpy

      $P1 = new 'Iterator', args
      unless $P1 goto zero_args
      $P0 = shift $P1
loop:
      unless $P1 goto end
      $P2 = shift $P1
			$P0 = .name($P0, $P2)
      goto loop
end:
      .return ($P0)
zero_args:
      .return (0)
   .end

   .sub .name :multi(ArcInt, ArcInt)
      .param int i1
      .param int i2
      $I0 = i1 .op i2
      .return ($I0)
   .end
   
   .sub .name :multi(ArcInt, ArcNum)
      .param int i1
      .param num i2
      $N0 = i1 .op i2
      .return ($N0)
   .end

   .sub .name :multi(ArcNum, ArcInt)
      .param num i1
      .param int i2
      $N0 = i1 .op i2
      .return ($N0)
   .end

   .sub .name  :multi(ArcNum, ArcNum)
      .param num i1
      .param num i2
      $N0 = i1 .op i2
      .return ($N0)
   .end

   .sub .name :multi(ArcInt)
     .param int i
     $I0 = 0 .op i
     .return ($I0)
  .end

  .sub .name :multi(ArcNum)
     .param num i
     $N0 = 0 .op i
     .return ($N0)
  .end

.endm

.defmathop('+', +)
.defmathop('-', -)
.defmathop('*', *)
.defmathop('/', /)

.sub 'mod'
   .param int a
   .param int b
   $I0 = mod a, b
   .return ($I0)
.end

.sub 'expt'
   .param num a
   .param num b
   $N0 = pow a, b
   .return ($N0)
.end

.sub 'sqrt'
   .param num a
   $N0 = sqrt a
   .return ($N0)
.end

.macro base_and_reduce_equality (name)

	 .sub .name :multi()
			.param pmc args :slurpy
			.local pmc nil
			nil = get_hll_global 'nil'
			$P0 = new 'Iterator', args
			unless $P0 goto yes
			$P1 = shift $P0
			$P2 = shift $P0
loop:
			$P3 = .name($P1, $P2)
			unless $P3 goto no
			unless $P0 goto yes
			$P1 = $P2
			$P2 = shift $P0
			goto loop
yes:
			$P0 = get_hll_global 't'
			.return ($P0)
no:
			.return (nil)
	 .end

	 .sub .name :multi(PMC)
			.param pmc a
			$P0 = get_hll_global 't'
			.return ($P0)
	 .end
	 
.endm

.base_and_reduce_equality('iso')

.sub 'iso' :multi(Cons, Cons)
	 .param pmc a
	 .param pmc b

	 .local pmc nil
	 nil = get_hll_global 'nil'
loop:
	 $P0 = car(a)
	 $P1 = car(b)
	 $P2 = 'iso'($P0, $P1)
	 unless $P2 goto no
	 a = cdr(a)
	 b = cdr(b)
	 unless a goto nil_b
	 if b goto loop
	 goto no
nil_b:
	 if b goto no
	 goto yes
no:
	 .return (nil)
yes:
	 $P0 = get_hll_global 't'
	 .return ($P0)
.end

.sub 'iso' :multi(_, _)
	 .param pmc a
	 .param pmc b
	 .tailcall 'is'(a, b)
.end

.base_and_reduce_equality('is')

.sub 'is' :multi(PMC, PMC)
   .param pmc a
   .param pmc b
   
   $S0 = typeof a
   $S1 = typeof b
   unless $S0 == $S1 goto no
   if $S0 == 'int' goto value_compare
   if $S0 == 'num' goto value_compare
   if $S0 == 'string' goto value_compare
	 if $S0 == 'char' goto value_compare
   
adress_compare:
   $I0 = issame a, b
   if $I0 goto yes
   goto no
value_compare:
   if a == b goto yes
no:
   $P0 = get_hll_global 'nil'
   .return ($P0)
yes:
   $P0 = get_hll_global 't'
   .return ($P0)
.end

.macro defcmp(name, op, t1, t2, t3)
   .sub .name :multi(.t1, .t2)
      .param .t3 n1
      .param .t3 n2
      
      if n1 .op n2 goto true
      $P0 = get_hll_global 'nil'
      .return ($P0)
true:
      $P0 = get_hll_global 't'
      .return ($P0)   
   .end
.endm

.macro wcmp(name, op)

	 .sub .name :multi()
			.param pmc args :slurpy
			.local pmc nil
			nil = get_hll_global 'nil'
			$P0 = new 'Iterator', args
			unless $P0 goto yes
			$P1 = shift $P0
			unless $P0 goto yes
			$P2 = shift $P0
loop:
			$P3 = .name($P1, $P2)
			$I0 = issame $P3, nil
			if $I0 goto no
			unless $P0 goto yes
			$P1 = $P2
			$P2 = shift $P0
			goto loop
yes:
			$P0 = get_hll_global 't'
			.return ($P0)
no:
			.return (nil)
	 .end

   .defcmp(.name, .op, ArcStr, ArcStr, string)
	 .defcmp(.name, .op, ArcChar, ArcChar, pmc)
	 .defcmp(.name, .op, ArcInt, ArcInt, int)
   .defcmp(.name, .op, ArcInt, ArcNum, num)
   .defcmp(.name, .op, ArcNum, ArcInt, num)
   .defcmp(.name, .op, ArcNum, ArcNum, num)
   
   .sub .name :multi(_, _)
      .param pmc a1
      .param pmc a2
      
      $S0 = "Can't compare "
      $S1 = typeof a1
      $S0 .= $S1
      $S0 .= " and "
      $S1 = typeof a2
      $S0 .= $S1
      'err'($S0)
      $P0 = get_hll_global 'nil'
      .return($P0)
   .end
	 
.endm

.wcmp('<', <)
.wcmp('>', >)

## copy a list
## return head of the list and the last cons cell
.sub 'copy'
   .param pmc l
   .local pmc nil
   .local pmc res
   .local pmc last

   nil = get_hll_global 'nil'
   last = nil
   res = nil
start:
   $I0 = issame nil, l
   if $I0 goto end
   $P0 = car(l)
   l = cdr(l)
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
   .return (res, last)
.end

.sub '+' :multi(ArcNil, Cons)
   .param pmc a
   .param pmc b
   
   .tailcall 'copy'(b)
.end

.sub '+' :multi(ArcNil, ArcNil)
	 .param pmc a
	 .param pmc b

	 .return (a)
.end

.sub '+' :multi(Cons, ArcNil)
   .param pmc a
   .param pmc b
   
   .tailcall 'copy'(a)
.end

.sub '+' :multi(Cons, Cons)
   .param pmc a
   .param pmc b
   .local pmc nil

   ($P0, $P1) = 'copy'(a)
   $P2 = 'copy'(b)
   scdr($P1, $P2)
   .return ($P0)
.end
   
.sub '+' :multi(ArcStr, ArcStr)
   .param pmc s1
   .param pmc s2

   $S0 = s1
   $S1 = s2
   $S0 .= $S1

   $P0 = new 'ArcStr'
   $P0 = $S0
   .return ($P0)
.end

.sub 'rand'
   .param int max
   $P0 = new 'Random'
   $I0 = $P0[max]
   .return ($I0)
.end

.sub 'trunc'
	 .param pmc x

	 $N0 = x
	 $I0 = $N0

	 .return ($I0)
.end

.sub 'ccc'
   .param pmc f

   interpinfo $P0, .INTERPINFO_CURRENT_CONT

   .tailcall f($P0)
.end

.sub 'pr'
   .param pmc what :slurpy

	 unless what goto end

   $P0 = get_hll_global 'stdout*'
   $P0 = getattribute $P0, 'stream'
	 
	 .local pmc x
	 x = shift what
loop:
   $S0 = x.'pr_repr'()
   $P0.'puts'($S0)
	 unless what goto end
	 x = shift what
	 goto loop
end:		
   .return (x)
.end

.sub 'prn'
   .param pmc what :slurpy

	 $P0 = get_hll_global 'stdout*'
   $P0 = getattribute $P0, 'stream'
	 $P1 = 'pr'(what :flat)
	 $P0.'puts'("\n")

   .return ($P1)
.end

.sub 'ero'
	 .param pmc what :slurpy

	 $P0 = get_hll_global 'stdout*'
	 $P1 = get_hll_global 'stderr*'
	 set_hll_global 'stdout*', $P1
	 $P1 = 'prn'(what :flat)
	 set_hll_global 'stdout*', $P0

	 .return ($P1)
.end

.sub 'eval'
   .param pmc what
	 .local pmc out
	 out = 'outstring'()
	 $P1 = get_hll_global 'stdout*'
	 set_hll_global 'stdout*', out
	 $P0 = get_hll_global 'tl-compile'
   $P0(what)
	 set_hll_global 'stdout*', $P1
   $P1 = compreg 'PIR'
	 $P0 = 'inside'(out)
#	 say $P0
   $P0 = $P1($P0)
   $P0()
   $P0 = get_hll_global '***' # !! I don't like this
   .return ($P0)
.end

## I/O

.sub 'stdin'
   $P0 = getstdin
   $P1 = new 'Inport'
   setattribute $P1, 'stream', $P0
   .return ($P1)
.end

.sub 'stdout'
   $P0 = getstdout
   $P1 = new 'Outport'
   setattribute $P1, 'stream', $P0
   .return ($P1)
.end

.sub 'stderr'
   $P0 = getstderr
   $P1 = new 'Outport'
   setattribute $P1, 'stream', $P0
   .return ($P1)
.end

.sub '_open_file'
   .param pmc fname
   .param pmc io_obj
   .param string direction

   $S0 = fname
   $P0 = new 'FileHandle'
   push_eh error
   $P0.'open'( $S0, direction )
   pop_eh
   setattribute io_obj, 'stream', $P0
   .return (io_obj)
error:
   .local pmc ex
   .get_results (ex)
   $S0 = "Can't open file: "
   $S1 = fname
   $S0 .= $S1
   $S0 = _str_err($S0)
	 .tailcall 'err'($S0)
.end

.sub 'infile'
   .param pmc fname
   $P0 = new 'Inport'
   .tailcall '_open_file'(fname, $P0, 'r')
.end

.sub 'outfile'
   .param pmc fname
   $P0 = new 'Outport'
   .tailcall '_open_file'(fname, $P0, 'w')
.end

.sub 'instring'
   .param pmc str
   $P0 = new 'ReadStream'
   $P0.'input'(str)
   .return ($P0)
.end

.sub 'outstring'
	 $P0 = new 'StringHandle'
	 $P0.'open'("", "w")
	 $P1 = new 'Outport'
	 setattribute $P1, 'stream', $P0
	 .return ($P1)
.end

.sub 'inside'
	 .param pmc str_oport

	 $P0 = getattribute str_oport, 'stream'
	 $S0 = $P0.'read'(0) # bytes num is ignored
	 $P0 = new 'ArcStr'
	 $P0 = $S0

	 .return ($P0)
.end

.sub 'pipe-from'
   .param pmc cmd
   $P0 = new 'Inport'
   .tailcall '_open_file'(cmd, $P0, 'rp')
.end

## not in Arc2
.sub 'pipe-to'
   .param pmc cmd
   $P0 = new 'Outport'
   .tailcall '_open_file'(cmd, $P0, 'wp')
.end

.include 'socket.pasm'

.sub 'open-socket'
	 .param pmc port

	 $I0 = port
	 $P0 = new 'ArcSocket'
	 $P1 = new 'Socket'
	 setattribute $P0, 'stream', $P1

	 .local pmc addr
	 $P1.'socket'(.PIO_PF_INET, .PIO_SOCK_STREAM, .PIO_PROTO_TCP)
	 addr = $P1.'sockaddr'('localhost', port)
	 $P1.'bind'(addr)
	 $P1.'listen'(1024) # randomly choosen

	 .return ($P0)
.end

.sub 'socket-accept'
	 .param pmc sock

	 .local pmc in
	 .local pmc out
	 .local pmc ip
	 
	 $P0 = getattribute sock, 'stream'
	 $P0 = $P0.'accept'()
	 ## !! in & out share the same filehandle
	 ## !! will create problems with close()
	 in = new 'Inport'
	 setattribute in, 'stream', $P0
	 out = new 'Outport'
	 setattribute out, 'stream', $P0
	 ip = new 'ArcStr'
	 ip = "" # TODO: implement
	 $P0 = get_hll_global 'nil'
	 $P0 = 'cons'(ip, $P0)
	 $P0 = 'cons'(out, $P0)
	 $P0 = 'cons'(in, $P0)

	 .return ($P0)
.end

.sub 'client-ip'
	 .param pmc sock
	 ## TODO
	 .return ("")
.end

.sub 'close'
   .param pmc port
   $P0 = getattribute port, 'stream'   
   $P0.'close'()
   $P0 = get_hll_global 'nil'
   .return ($P0)
.end

.sub 'readc'
   .param pmc inport :optional
   .param int has_in :opt_flag
   if has_in goto do
   inport = get_hll_global 'stdin*'
do:
	 $P0 = new 'ArcChar'
	 $S0 = inport.'get1'()
	 $P0 = $S0
	 .return ($P0)
.end
   
.sub 'readb'
   .param pmc inport :optional
   .param int has_in :opt_flag
   if has_in goto do
   inport = get_hll_global 'stdin*'
do:
	 $P0 = new 'ArcChar'
	 $S0 = inport.'get1'()
	 $P0 = $S0
	 .return ($P0)
.end

.sub 'peekc'
   .param pmc inport :optional
   .param int has_in :opt_flag
   if has_in goto do
   inport = get_hll_global 'stdin*'
do:
	 $P0 = new 'ArcChar'
	 $S0 = inport.'peek1'()
	 $P0 = $S0
	 .return ($P0)
.end

.sub 'read'
   .param pmc inport :optional
   .param int has_in :opt_flag
   if has_in goto do
   inport = get_hll_global 'stdin*'
do:
   .tailcall _read(inport)
.end

.sub 'writec'
   .param pmc c
   .param pmc outport :optional
   .param int has_out :opt_flag
   if has_out goto do
   outport = get_hll_global 'stdout*'
do:
   $P0 = getattribute outport, 'stream'
   $S0 = c.'pr_repr'()
   $P0.'puts'($S0)
   
   .return (c)
.end

.sub 'writeb'
   .param pmc c
   .param pmc outport :optional
   .param int has_out :opt_flag
   if has_out goto do
   outport = get_hll_global 'stdout*'
do:
   .tailcall 'writec'(c, outport)
.end

.sub 'write'
   .param pmc what
   .param pmc outport :optional
   .param int has_out :opt_flag
   if has_out goto do
   outport = get_hll_global 'stdout*'
do:
	 $S1 = what.'to_string'() # conversion
   $P0 = getattribute outport, 'stream'
   $P0.'puts'($S1)
   .return (what)
.end

.sub 'disp'
   .param pmc what
   .param pmc outport :optional
   .param int has_out :opt_flag
   if has_out goto do
   outport = get_hll_global 'stdout*'
do:
   $S0 = what.'pr_repr'() # conversion
   $P0 = getattribute outport, 'stream'
   $P0.'puts'($S0)
   .return (what)
.end

.macro defcallw(name, toport)
   .sub .name
      .param pmc port
      .param pmc fn
      $P0 = get_hll_global .toport # save
      set_hll_global .toport, port # set
      $P1 = arcall(fn)
      set_hll_global .toport, $P0 # restore
      .return ($P1)
   .end
.endm

.defcallw('call-w/stdin', 'stdin*')
.defcallw('call-w/stdout', 'stdout*')

.sub 'load'
   .param pmc file

   $P0 = 'infile'(file)
   $P2 = get_hll_global 'nil'
loop:
   $P1 = 'read'($P0)
   $S0 = typeof $P1
   if $S0 == 'eof' goto end
   $P2 = 'eval'($P1)
   goto loop
end:
   .return ($P2)
.end

.sub 'system'
   .param pmc cmd
   $S0 = cmd
   $I0 = spawnw $S0
   $P0 = new 'ArcInt'
   $P0 = $I0
   .return ($P0)
.end

.sub 'dir'
   .param pmc path
   $S0 = path
   $P0 = new 'OS'
   $P0 = $P0.'readdir'($S0)
   .tailcall 'list'($P0 :flat)
.end

.sub 'rmfile'
   .param pmc path
   $S0 = path
   $P0 = new 'OS'
   push_eh error
   $P0.'rm'(path)
   pop_eh
   $P0 = get_hll_global 'nil'
   .return ($P0)
error:
   .local pmc ex
   .get_results(ex)
   $S0 = _str_err(ex)
   ex = $S0
   rethrow ex
.end

.sub 'file-exists'
   .param pmc path
   $S0 = path
   $I0 = stat $S0, 0
   if $I0 goto true
   $P0 = get_hll_global 'nil'
   .return ($P0)
true:
   $P0 = get_hll_global 't'
   .return ($P0)
.end

.sub 'dir-exists'
   .param pmc path
   $S0 = path
   $I0 = stat $S0, 0
   unless $I0 goto false
   $I0 = stat $S0, 2
   unless $I0 goto false
   $P0 = get_hll_global 't'
   .return ($P0)
false:
   $P0 = get_hll_global 'nil'
   .return ($P0)
.end

.sub 'sleep'
   .param int n
   sleep n
   $P0 = get_hll_global 'nil'
   .return ($P0)
.end

.sub 'maptable'
   .param pmc fn
   .param pmc table

   .local pmc iter

   iter = new 'Iterator', table
loop:
   unless iter goto end
   $P0 = shift iter
   $P1 = table[$P0]
   arcall2(fn, $P0, $P1)
   goto loop
end:
   .return (table)
.end

.sub 'atomic-invoke'
	 .param pmc f
	 ## TODO: make really atomic
	 .tailcall 'arcall'(f)
.end

##!! doesn't work
.sub 'new-thread'
   .param pmc fn

	 .local pmc thr
	 thr = new 'ParrotThread'
   #.include 'cloneflags.pasm'
   .local int flags
   #flags  = .PARROT_CLONE_CODE
   #flags |= .PARROT_CLONE_CLASSES
	 #flags |= .PARROT_CLONE_HLL
	 #flags |= .PARROT_CLONE_GLOBALS
	 #flags |= .PARROT_CLONE_LIBRARIES
	 #flags |= .PARROT_CLONE_RUNOPS

	 thr.'run_clone'(fn)

   .return (thr)
.end

.sub 'kill-thread'
	 .param pmc thr
	 thr.'kill'()
	 $P0 = get_hll_global 'nil'
	 .return ($P0)
.end

.sub 'break-thread'
	 .param pmc thr
	 $P0 = get_hll_global 'nil'
	 .return ($P0)
.end

.sub 'bound'
   .param pmc sym

   $S0 = sym.'to_string'()
   $P0 = get_hll_global $S0
   if_null $P0, false
   $P0 = get_hll_global 't'
   .return ($P0)
false:
   $P0 = get_hll_global 'nil'
   .return ($P0)
.end

.sub 'newstring'
   .param int n
   .param string c :optional
   .param int has_c :opt_flag

   if has_c goto go_on
   c = " "
go_on:  
   $S0 = ""
loop:
   if n >= 0 goto end
   $S0 .= c
   n = n - 1
   goto loop
end:
   $P0 = new 'ArcStr'
   $P0 = $S0
   .return ($P0)
.end

.sub 'string'
	 .param pmc args :slurpy

	 $S0 = ""
loop:
	 unless args goto end
	 $P0 = shift args
	 $S1 = $P0.'pr_repr'()
	 $S0 .= $S1
	 goto loop
end:
	 $P0 = new 'ArcStr'
	 $P0 = $S0
	 .return ($P0)
.end

.sub 'on-err'
	 .param pmc err_fn
	 .param pmc fn

	 push_eh handle_err
	 $P0 = 'arcall'(fn)
	 pop_eh
	 .return ($P0)
handle_err:
	 .get_results ($P0)
	 $P0 = get_hll_global 'nil'
	 .tailcall 'arcall'(err_fn, $P0)
.end

.sub 'details'
	 .param pmc ex
	 $S0 = ex.'to_string'()
	 .return ($S0)
.end

## only stubs

.sub 'msec'
   .return (0)
.end

.sub 'current-process-milliseconds'
	 .return (0)
.end

.sub 'current-gc-milliseconds'
	 .return (0)
.end

.sub 'seconds'
	 .return (0)
.end
