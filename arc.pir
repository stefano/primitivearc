.HLL 'Arc'

.namespace [ ]

## load ops
.loadlib 'primitivearc_ops'
## load pmc
.loadlib 'primitivearc_group'

.include 'types.pir'
.include 'symtable.pir'
.include 'arcall.pir'
.include 'compiler.pir'
.include 'read.pir'
.include 'builtins.pir'

.sub '_main' :main
    .param pmc args
		.local int is_pir
		is_pir = 0

		load_bytecode 'ac/boot.pbc'
		load_bytecode 'ac/comp.pbc'
		load_bytecode 'ac/qq.pbc'
		load_bytecode 'aa.pbc'
		
    ## register the sub _compile as the compilation function for Arc
    $P0 = get_hll_global '_compile_and_eval'
    compreg 'Arc', $P0
    
    ## for every file in the command line, compile it
    .local pmc iter
    iter = new 'Iterator', args
    $S0 = shift iter # skip first arg (the compiler program)

    ## default value for ***
    $P1 = get_hll_global 'nil'
    set_hll_global '***', $P1
		#push_eh run_error
loop:
    unless iter goto end 
    $S0 = shift iter
    if $S0 == '-e' goto eval_mode # enter evaluation mode
		unless $S0 == '-pir' goto go_on
		$S0 = shift iter
		is_pir = 1
go_on:
    $S0 = file_to_string($S0)
		unless is_pir goto compile_arc
		$P0 = compreg 'PIR'
		$P0 = $P0($S0)
		$P0()
		goto loop
compile_arc:		
    $P0 = _compile_and_eval($S0)
    goto loop
end:
    $P1 = get_hll_global '***'
		'write'($P1)
		'prn'()
    goto the_end
run_error:
    .get_results($P2)
    say $P2
    goto the_end
eval_mode:
    $P0 = getstdin
loop2:
    #push_eh error # never give up
    $S0 = $P0.'readline_interactive'( 'arc> ' )
    $P2 = _compile_and_eval($S0)
		##print ' -> '
    'prn'($P2)
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

.sub '_compile_and_eval'
   .param string src
   .local pmc code

   ## wrap code in a function call to execute all expressions
   $S0 = "((fn () "
   $S0 .= src
   $S0 .= "))"
   $P1 = new 'ReadStream'
   $P1.'input'($S0)
   $P0 = _read($P1)
   #code = _tl_compile($P0)
   
   ## get PIR compiler and compile the emitted PIR code
   #$P0 = compreg 'PIR'
																				#$P1 = $P0(code)
	 $P1 = 'eval'($P0)
   .return ($P1)
.end
