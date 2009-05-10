.HLL 'Arc'

.namespace [ ]

.sub '__onload' :init
   ## load dynamic PMCs
   loadlib $P0, 'primitivearc_group'
.end

.sub '_main' :main
    .param pmc args

    ## register the sub _compile as the compilation function for Arc
    $P0 = get_hll_global '_compile'
    compreg 'Arc', $P0
    
    ## for every file in the command line, compile it
    .local pmc iter
    iter = new 'Iterator', args
    $S0 = shift iter # skip first arg (the compiler program)

    ## default value for ***
    $P1 = get_hll_global 'nil'
    set_hll_global '***', $P1
    push_eh run_error
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
run_error:
    .get_results($P2)
    say $P2
    goto the_end
eval_mode:
    $P0 = getstdin
loop2:
    push_eh error # never give up
    $S0 = $P0.'readline_interactive'( 'arc> ' )
    $P1 = _compile($S0)
    $P1()
    $P2 = get_hll_global '***'
    #print ' -> '
    say $P2
    goto loop2
error:
    .get_results($P2)
    say $P2
    goto loop2
the_end:        
.end

.sub 'file_to_string'
   .param string name
   .local pmc handle
   .local string res
   
   handle = new 'FileHandle'
   push_eh error
   res = handle.'readall'( name )
   pop_eh
   handle.'close'()
   .return (res)
error:
   .local pmc ex
   .get_results (ex)
   ex = "File error"
   rethrow ex
.end

.sub '_compile'
   .param string src
   .local pmc code

   ## wrap code in a function call to execute all expressions
   $S0 = "((fn () "
   $S0 .= src
   $S0 .= "))"
   $P1 = new 'ReadStream'
   $P1.'input'($S0)
   $P0 = _read($P1)
   code = _tl_compile($P0)
   
   ## get PIR compiler and compile the emitted PIR code
   $P0 = compreg 'PIR'
   $P1 = $P0(code)
   .return ($P1)
.end

.include 'types.pir'
.include 'symtable.pir'
.include 'arcall.pir'
.include 'compiler.pir'
.include 'read.pir'
.include 'builtins.pir'
