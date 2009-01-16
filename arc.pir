.HLL 'Arc'

.namespace [ ]

.sub _init :anon :init :load
   load_bytecode 'types.pbc'
   load_bytecode 'symtable.pbc'
   load_bytecode 'arcall.pbc'
   load_bytecode 'compiler.pbc'
   load_bytecode 'read.pbc'
   load_bytecode 'builtins.pbc'
.end

.sub _main :main
    .param pmc args

    ## register the sub _compile as the compilation function for Arc
    $P0 = get_hll_global '_compile'
    compreg 'Arc', $P0

    ## for every file in the command line, compile it
    .local pmc iter
   # .local pmc compiler
    iter = new 'Iterator', args
    $S0 = shift iter # skip first arg (the compiler program)
  #  compiler = compreg 'Arc'
loop:
    unless iter goto end 
    $S0 = shift iter
    if $S0 == '-e' goto eval_mode # enter evaluation mode 
    $S0 = file_to_string($S0)
    $P0 = _compile($S0)
    $P0() # run the just compiled bytecode
    goto loop
end:
    $P1 = get_hll_global '***'
    say $P1
    goto the_end
eval_mode:      
    ##    say 'Done'
    $P0 = getstdin
    .local pmc out
    out = getstdout
    $P1 = new 'ReadStream'
loop2:
    push_eh error # never give up
    print out, "arc> "
    out.'flush'()
    $S0 = readline $P0
    #$P1.'input'($S0)
    #$P2 = _read($P1)
    #say $P2
    #say ''
    #_tl_compile($P2)
#    say '---'
    $P1 = _compile($S0)
    $P1()
    $P2 = get_hll_global '***'
    #print ' -> '
    say $P2
    goto loop2
error:
    .get_results($P2)
    say $P2
    goto loop
the_end:        
.end

.sub file_to_string
   .param string name
   .local pmc handle
   .local string res
   
   handle = open name, '<'
   unless handle goto file_error
loop:
   unless handle goto end
   $S0 = readline handle
   res .= $S0
   goto loop
end:
   close handle
   .return (res)
file_error:
   close handle
   die "File error"
   .return ()
.end

.sub _compile
   .param string src
   .local pmc code
      
#   say "Compiling..."
#   say src
   $P1 = new 'ReadStream'
   $P1.'input'(src)
   $P0 = _read($P1)
   code = _tl_compile($P0)
   
   ## get PIR compiler and compile the emitted PIR code
   $P0 = compreg 'PIR'
   $P1 = $P0(code)
   .return ($P1)
.end
