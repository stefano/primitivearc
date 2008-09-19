.HLL 'Arc', ''

.namespace [ ]

.sub _init :anon :init :load
   load_bytecode 'types.pbc'
   load_bytecode 'symtable.pbc'
   load_bytecode 'arcall.pbc'
   load_bytecode 'compiler.pbc'
   load_bytecode 'read.pbc'
.end

.sub _main :main
    .param pmc args

    ## register the sub _compile as the compilation function for Arc
    P0 = get_hll_global '_compile'
    compreg 'Arc', P0

    ## for every file in the command line, compile it
#    .local pmc iter
#    .local pmc compiler
#    iter = new 'Iterator', args
#    S0 = shift iter # skip first arg (the compiler program)
#    compiler = compreg 'Arc'
#loop:
#    unless iter goto end 
#    S0 = shift iter
#    S0 = file_to_string(S0)
#    P0 = compiler(S0) # compilation returns a sub representing the program
#    say 'Running...'
#    P0() # run the just compiled bytecode
#    goto loop
#end:	
#    say 'Done'
    P0 = getstdin
    P1 = new 'ReadStream'
loop:
    S0 = readline P0
    P1.input(S0)
    P2 = _read(P1)
    P7 = new 'ResizablePMCArray'
    P8 = new 'String'
    P8 = ""
    P3 = _collect_fn(P2, P7, P8)
    P4 = _empty_state()
    say '---'
    _compile_expr(P4, P2)
    P6 = getattribute P4, 'code'
    S0 = P6
    say S0
loop1:
    unless P3 goto end
    P4 = shift P3
    P5 = _empty_state()
    ## _compile_expr(P5, P4)
    _compile_fn(P5, P4)
    P6 = getattribute P5, 'code'
    S0 = P6
    say S0    
    goto loop1
end:	
    say '---'
    goto loop
.end

.sub file_to_string
   .param string name
   .local pmc handle
   .local string res
   
   handle = open name, '<'
   unless handle goto file_error
loop:
   unless handle goto end
   S0 = readline handle
   res .= S0
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
   code = new 'CodeString'
   
   say "Compiling..."

   code.emit(<<"END")
.sub _main :main :anon
   say "Hi!"
   .return ()
.end
END
   
   say "Result:"
   say code
   
   ## get PIR compiler and compile the emitted PIR code
   P0 = compreg 'PIR'
   .return P0(code)
.end
