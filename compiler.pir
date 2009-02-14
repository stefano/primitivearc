.HLL 'Arc'

.sub _init :anon :load :init

   ## class holding information needed by compilation
   $P0 = newclass 'CompilerState'
   addattribute $P0, 'code' # CodeString of code emitted so far
   addattribute $P0, 'lex' # list of lexical variables (symbols)
   addattribute $P0, 'nextreg' # number of next free register to use

   ## function information
   $P0 = newclass 'FnInfo'
   addattribute $P0, 'expr' # s-expr ($fn name (args ...) body)
   addattribute $P0, 'globalp' # is this a global function (not a closure)?
   addattribute $P0, 'lex' # list of lexical variables at definiton time
   addattribute $P0, 'outer' # name of external function

   ## constant value information
   $P0 = newclass 'ConstInfo'
   addattribute $P0, 'expr'
   addattribute $P0, 'name' # global name of constant
   
   ## function arg information
   $P0 = newclass 'ArgInfo'
   addattribute $P0, 'sym'
   addattribute $P0, 'type' # only 'normal' or 'rest' for now
   addattribute $P0, 'rep' # parrot representaion 
   
   .return ()
.end

.namespace [ 'CompilerState' ]

## get name of next free register
.sub _next_reg :method
   $P0 = getattribute self, 'nextreg'
   $P0 += 1
   setattribute self, 'nextreg', $P0

   $S0 = '$P'
   $S1 = $P0
   $S0 .= $S1
   .return ($S0)
.end

## mark all registers as free
.sub _reset_reg :method
   $P0 = getattribute self, 'nextreg'
   $P0 = 0
   setattribute self, 'nextreg', $P0
   .return ()
.end

## mark last allocated register as free, return freed register name
.sub _free_reg :method
   $P0 = getattribute self, 'nextreg'
   $S0 = '$P'
   $S1 = $P0
   $S0 .= $S1
   $P0 -= 1
   setattribute self, 'nextreg', $P0
   .return ($S0)
.end

## simulate a push on a stack using registers, return reg name
.sub _push :method
   .tailcall self.'_next_reg'()
.end

## simulate a pop, return register name with value
## use the value before a push is made!
.sub _pop :method
   .tailcall self.'_free_reg'()
.end

.sub _top :method
   $P0 = getattribute self, 'nextreg'
   $S0 = '$P'
   $S1 = $P0
   $S0 .= $S1
   .return ($S0)
.end

.namespace [ ]

## create a new empty CompilerState
.sub _empty_state
   $P0 = new 'CompilerState'
   $P1 = new 'CodeString'
   setattribute $P0, 'code', $P1
   $P1 = new 'ResizablePMCArray'
   setattribute $P0, 'lex', $P1
   $P1 = new 'Integer'
   $P1 = 0
   setattribute $P0, 'nextreg', $P1

   .return ($P0)
.end

## top level compilation
.sub _tl_compile
   .param pmc expr
   .local pmc fns
   .local pmc consts
   .local pmc code

##   say 'Compilation result:'
##   say ''
   
   $P0 = new 'ResizablePMCArray'
   $P1 = new 'String'
   $P1 = ""
   (fns, consts, expr) = _collect_fn_and_consts(expr, $P0, $P1, 0)
   $P0 = _empty_state()
   code = getattribute $P0, 'code'
   code.'emit'(".HLL 'Arc'")
   ## main function
   code.'emit'(".sub _main :anon")
   _compile_expr($P0, expr, 0)
   $S0 = $P0.'_pop'() # return register
   ## put return value in global var '***
   code.'emit'("set_hll_global '***', %0", $S0)
   code.'emit'("   .return ()")
   code.'emit'(".end")

   ## initialization stuff
loop:
    unless fns goto end
    $P0 = pop fns
    $P1 = _empty_state()
    setattribute $P1, 'code', code # retain previous code
    _compile_fn($P1, $P0)
    code.'emit'("\n")
    goto loop
end:
    $P0 = _empty_state()
    setattribute $P0, 'code', code # retain previous code
    code = getattribute $P0, 'code'
    code.'emit'(".sub _const_init :anon :init")
loop1:
    unless consts goto end1
    $P1 = shift consts
    _compile_const($P0, $P1)
    goto loop1
end1:
    code.'emit'(".return ()")
    code.'emit'(".end")
    #$S0 = code
    #say $S0
    .return (code)
.end
 
## takes a list of ArgInfo and a symbol
## tells if symbol referes to a lexical variable
.sub _lexical
   .param pmc lst
   .param pmc sym

   $P0 = new 'Iterator', lst
loop:
   unless $P0 goto no
   $P1 = shift $P0
   $P1 = getattribute $P1, 'sym'
   $I0 = issame sym, $P1
   if $I0 goto yes
   goto loop
no:	
   .return (0)
yes:	
   .return (1)
.end

## compile a single expression
.sub _compile_expr
   .param pmc cs
   .param pmc expr
   .param int is_tail

   .local pmc code
   .local string type
   .local string out_reg
   .local int apply 
   code = getattribute cs, 'code'
   type = typeof expr
   out_reg = cs.'_push'() # output register
   apply = 0 # normal function call by default
   
   if type == 'Nil' goto is_nil
   if type == 'T' goto is_t
   if type == 'String' goto str
   if type == 'Integer' goto int_num
   if type == 'Float' goto float_num
   if type == 'Symbol' goto var_ref
   if type == 'Cons' goto special_or_call

   ## unknown expression
   $S0 = "Unknown expression: "
   $S1 = expr
   $S0 .= $S1
   'err'($S0)
   .return ()

is_nil:
   $P0 = get_hll_global 'nil'
   code.'emit'("%0 = get_hll_global 'nil'", out_reg)
   .return ()
is_t:
   $P0 = get_hll_global 't'
   code.'emit'("%0 = get_hll_global 't'", out_reg)
   .return ()
str:
   $S1 = code.'escape'(expr) # value
   code.'emit'("%0 = new 'String'\n", out_reg)
   code.'emit'("%0 = %1\n", out_reg, $S1)
   .return ()
int_num:
   code.'emit'("%0 = new 'Integer'\n", out_reg)
   code.'emit'("%0 = %1\n", out_reg, expr)
   .return ()
float_num:	
   code.'emit'("%0 = new 'Float'\n", out_reg)
   code.'emit'("%0 = %1\n", out_reg, expr)
   .return ()
var_ref: # variable reference
   $P0 = getattribute cs, 'lex'
   $I0 = _lexical($P0, expr)
   if $I0 goto lex
   ## ?? should escape symbol? the only character that could create
   ## ?? problems is ', and it won't appear in a symbol once
   ## ?? quoting is implemented
   code.'emit'("%0 = get_hll_global '%1'", out_reg, expr)
   ## !! TODO: avoid to emit this check for globals holding values
   ## !! generated by the compiler
   _emit_check_defined(code, out_reg, expr)
   .return ()
lex:
   code.'emit'("%0 = find_lex '%1'", out_reg, expr)
   .return ()
special_or_call:
   $P0 = car(expr)
   $S0 = typeof $P0
   unless $S0 == 'Symbol' goto is_call
   $S0 = $P0
   if $S0 == "$function" goto new_function
   if $S0 == "$closure" goto new_closure
   if $S0 == "if" goto if_expr
   if $S0 == "set" goto set_expr
   if $S0 == "apply" goto apply_expr
   goto is_call
new_function:	# function creation
   .tailcall _compile_function(cs, expr, out_reg)
new_closure:	# closure creation
   .tailcall _compile_closure(cs, expr, out_reg)
if_expr:
   .tailcall _compile_if(cs, expr, out_reg, is_tail)
set_expr:
   .tailcall _compile_set(cs, expr, out_reg)
apply_expr:
   expr = cdr(expr) # cut 'apply
   apply = 1
   ## go on with function call code
is_call:
   .local pmc args # array holding function & arguments registers
   args = new 'ResizableStringArray'
   $I0 = 0
args_loop:	# compile every argument
   $S0 = typeof expr
   unless $S0 == 'Cons' goto args_emitted
   $P0 = car(expr)
   _compile_expr(cs, $P0, 0)
   $I0 += 1
   expr = cdr(expr)
   goto args_loop
   ## put register names in args
args_emitted:
   if $I0 == 0 goto end_args
   $S0 = cs.'_pop'()
   unshift args, $S0
   $I0 -= 1
   goto args_emitted
end_args:
   .local string call_fn
   call_fn = "'arcall'"
   $I0 = args
   $I0 -= 1
   if $I0 == 1 goto call1
   if $I0 == 2 goto call2
   goto do_call
call1:
   call_fn = "arcall1"
   goto do_call
call2:
   call_fn = "arcall2"
   goto do_call
do_call:	
   if apply goto is_apply
   if is_tail goto tail_call
   code .= out_reg
   code .= " = "
   code .= call_fn
   code.'emit'("(%,)\n", args :flat)
   .return ()
tail_call:
   code .= ".tailcall "
   code .= call_fn
   code.'emit'("(%,)\n", args :flat)
   .return ()
is_apply:
   $I0 = args
   $I0 -= 1
   if $I0 == 0 goto no_args # only the function
   $P0 = args[$I0] # last argument
   code.'emit'("%0 = _list_to_array(%0)", $P0) # convert to array to flatten
   if is_tail goto tail_apply
   code .= out_reg
   code .= " = "
   code .= call_fn
   code.'emit'("(%, :flat)\n", args :flat)
   .return ()
tail_apply:
   code .= ".tailcall "
   code .= call_fn   
   code.'emit'("(%, :flat)\n", args :flat)
   .return ()
no_args:
   $P0 = args[0]
   if is_tail goto tail_no_args
   code .= out_reg
   code .= " = "
   code .= call_fn
   code.'emit'("(%0)", $P0)
   .return ()
tail_no_args:
   code .= ".return "
   code .= call_fn
   code.'emit'("(%0)", $P0)
   .return ()
.end

## emit code to create a constant value
.sub _compile_const
   .param pmc cs
   .param pmc cinfo
   .local pmc code
   .local pmc expr
   .local string out
   .local string out_reg
   
   code = getattribute cs, 'code'
   expr = getattribute cinfo, 'expr'
   $P0 = getattribute cinfo, 'name'
   _emit_const(cs, expr)
   $S0 = cs.'_pop'()
   code.'emit'("set_hll_global '%0', %1", $P0, $S0)

   .return ()
.end

.sub _emit_const
   .param pmc cs
   .param pmc expr
   .local pmc code

   code = getattribute cs, 'code'
   $S0 = typeof expr
   if $S0 == 'Symbol' goto a_sym
   if $S0 == 'Cons' goto a_cons   
   ## code for self evaluating constants
   .tailcall _compile_expr(cs, expr, 0)
a_sym:
   $S0 = expr
   $S1 = cs.'_push'()
   code.'emit'("%0 = intern('%1')", $S1, $S0)
   .return ()
a_cons:
   $P0 = car(expr)
   $P1 = cdr(expr)
   _emit_const(cs, $P0)
   _emit_const(cs, $P1)
   $S0 = cs.'_pop'() # cdr register
   $S1 = cs.'_pop'() # car register
   $S2 = cs.'_push'() # result
   code.'emit'("%0 = cons(%1, %2)", $S2, $S1, $S0)
   .return ()
.end

.sub _emit_fn_head
   .param pmc cs
   .param string name
   .param string outer
   
   $P0 = getattribute cs, 'code'
   if outer == "" goto is_global
   goto not_global
is_global:	
   $P0.'emit'(".sub %0", name)
   .return ()
not_global:
   $P0.'emit'(".sub %0 :outer('%1')", name, outer)
   .return () 
.end

## emit a sequence of operations
## if sequence is empty, emit code to return nil
.sub _compile_seq
   .param pmc cs
   .param pmc seq

   .local pmc nil
   nil = get_hll_global 'nil'

   $I0 = issame seq, nil
   if $I0 goto empty_seq
   
   $P0 = seq 
loop:
   $I0 = issame seq, nil
   if $I0 goto end # list finished
   $S0 = typeof seq
   unless $S0 == 'Cons' goto error # dotted list?
   $P1 = car($P0) # expression to compile
   $P0 = cdr($P0) # advance
   $I0 = issame $P0, nil
   if $I0 goto last
   _compile_expr(cs, $P1, 0)
   cs.'_pop'() # ignore return register of this expression
   goto loop
last:	# last expression
   _compile_expr(cs, $P1, 1) # tail position
end:	
   .return ()
empty_seq:
   _compile_expr(cs, nil, 1) # code to return nil
   .return ()
error:
   die "Sequence is not a proper list!"
   .return ()
.end

## compiles a global function expression
## takes an 'FnInfo' class
## ($fn name (arg1 ... . rest-arg) ...)
.sub _compile_fn
   .param pmc cs
   .param pmc fn
   .local pmc expr

   expr = getattribute fn, 'expr'
   $P0 = cdr(expr)
   $P0 = car($P0) # cadr: function name
   $S0 = typeof $P0
   unless $S0 == 'Symbol' goto not_a_sym_err
   $S0 = $P0
   $P1 = getattribute fn, 'outer'
   $S1 = $P1
   _emit_fn_head(cs, $S0, $S1)

   .local pmc code
   .local pmc args
   code = getattribute cs, 'code'

   $P2 = cdr(expr)
   $P2 = cdr($P2)
   $P2 = car($P2) # 3rd element: arg. list
   ## emit code for each name in arg. list
   args = new 'ResizablePMCArray'
   _collect_names($P2, args)
   ## parameter declaration
   $P2 = new 'Iterator', args
loop:
   unless $P2 goto end
   $P3 = shift $P2
   $P4 = getattribute $P3, 'type'
   $S0 = $P4
   $P4 = getattribute $P3, 'rep'
   if $S0 == 'normal' goto norm
   if $S0 == 'rest' goto rest
   die "Unknown parameter type!"
   .return ()
norm:
   code.'emit'(".param pmc %0", $P4)
   goto end_if
rest:
   code.'emit'(".param pmc %0 :slurpy", $P4)
   code.'emit'("%0 = list(%0 :flat)", $P4) # !! slow
end_if:	
   goto loop
end:
   ## lexical names
   $P2 = new 'Iterator', args
loop_lex:
   unless $P2 goto end_lex
   $P3 = shift $P2
   $P4 = getattribute $P3, 'sym'
   $S0 = $P4
   $P4 = getattribute $P3, 'rep'
   $S1 = $P4
   code.'emit'(".lex '%0', %1", $S0, $S1)
   goto loop_lex
end_lex:
   ## emit the body
   $P0 = cdr(expr)
   $P0 = cdr($P0)
   $P0 = cdr($P0) # cdddr: the body
   cs.'_reset_reg'() # at the start of a function all regs are free
   $P1 = getattribute fn, 'lex'
   $P2 = getattribute cs, 'lex' # previous lexicals
   setattribute cs, 'lex', $P1 # new lexicals
   _compile_seq(cs, $P0)
   setattribute cs, 'lex', $P2 # restore lexicals
   $S0 = cs.'_pop'() # register to return
   ## if last expression is a tail call the following return will be
   ## ignored, so it is safe to emit it anyway
   code.'emit'(".return (%0)", $S0) 
   code.'emit'(".end")
   .return ()
not_a_sym_err:
   die "Not a symbol!"
   .return ()
.end

## compile closure creation form
## ($closure code-name)
.sub _compile_closure
   .param pmc cs
   .param pmc expr
   .param string out_reg

   $P0 = cdr(expr)
   $P0 = car($P0) # cadr: code-name
   $S0 = $P0
   .local pmc code
   code = getattribute cs, 'code'
   code.'emit'("%0 = get_hll_global '%1'\n", out_reg, $S0) # get the global Sub
   code.'emit'("%0 = newclosure %0", out_reg) # create the closure
   .return ()
.end

## compile function creation form
## ($function code-name)
.sub _compile_function
   .param pmc cs
   .param pmc expr
   .param string out_reg

   $P0 = cdr(expr)
   $P0 = car($P0) # cadr: code-name
   $S0 = $P0
   .local pmc code
   code = getattribute cs, 'code'
   code.'emit'("%0 = get_hll_global '%1'\n", out_reg, $S0) # get the global Sub
   .return ()
.end

## if form: (if t1 then1 t2 then2 ... else)
## TODO: give better names to labels
.sub _compile_if
   .param pmc cs
   .param pmc expr
   .param string out_reg
   .param int is_tail
   
   $P0 = uniq()
   $S0 = $P0
   $P0 = cdr(expr) # throw away 'if
   
   _compile_if_rec(cs, $P0, out_reg, $S0, is_tail)
   $P0 = getattribute cs, 'code'
   $P0.'emit'("%0:", $S0)
   .return ()
.end

.sub _compile_if_rec
   .param pmc cs
   .param pmc expr
   .param string out_reg
   .param string end_label
   .param int is_tail
   .local pmc code
   .local pmc nil

   nil = get_hll_global 'nil'
   code = getattribute cs, 'code'
   $I0 = len(expr)
   if $I0 == 0 goto ret_nil
   if $I0 == 1 goto else_part
   ## $I0 > 1
   .local string else
   $P0 = uniq() # else part
   else = $P0
   $P1 = car(expr) # test
   $P2 = cdr(expr)
   $P2 = car($P2) # then part
   _compile_expr(cs, $P1, 0) # compile the test (never tail)
   $S0 = cs.'_push'()
   code.'emit'("%0 = get_hll_global 'nil'", $S0)
   cs.'_pop'()
   $S1 = cs.'_pop'()
   code.'emit'("$I0 = issame %0, %1", $S0, $S1)
   code.'emit'("if $I0 goto %0", else)
   ## then emission
   _compile_expr(cs, $P2, is_tail) # tail if 'if expression is in tail
   $S0 = cs.'_pop'() # take result  
   code.'emit'("%0 = %1", out_reg, $S0) # put it in output register
   code.'emit'("goto %0", end_label)
   ## else emission
   code.'emit'("%0:", else)
   $P0 = cdr(expr)
   $P0 = cdr($P0)
   .tailcall _compile_if_rec(cs, $P0, out_reg, end_label, is_tail)
else_part:
   $P0 = car(expr) # only element
   _compile_expr(cs, $P0, is_tail) # tail if 'if expression is in tail
   $S0 = cs.'_pop'()
   code.'emit'("%0 = %1", out_reg, $S0)
   .return ()
ret_nil:
   code.'emit'("%0 = get_hll_global 'nil'", out_reg)
   .return ()
.end

.sub _compile_set
   .param pmc cs
   .param pmc expr
   .param string out_reg
   .local pmc nil
   .local pmc code
   
   nil = get_hll_global 'nil'
   code = getattribute cs, 'code'
   expr = cdr(expr) # throw away 'set
loop:
   $I0 = issame expr, nil
   if $I0 goto end
   $I0 = len(expr)
   if $I0 < 2 goto error
   $P0 = car(expr) # var to set
   $S0 = typeof $P0
   unless $S0 == 'Symbol' goto error # var must be a symbol
   expr = cdr(expr)
   $P1 = car(expr) # value
   _compile_expr(cs, $P1, 0) # not tail
   $S0 = cs.'_pop'()
   code.'emit'("%0 = %1", out_reg, $S0) # return the value
   $P1 = getattribute cs, 'lex'
   $I0 = _lexical($P1, $P0)
   $S1 = $P0
   if $I0 goto is_lex
   ## global
   code.'emit'("set_hll_global '%0', %1", $S1, $S0)
   goto next
is_lex:
   code.'emit'("store_lex '%0', %1", $S1, $S0)
next:	
   expr = cdr(expr) # advance
   goto loop
error:
   die "Malformed set!"
   .return ()
end:	
   .return ()
.end

## collect ArgInfo in a list into an array
.sub _collect_names
   .param pmc args
   .param pmc into
   .local pmc nil
   
   nil = get_hll_global 'nil'
  
loop:
   $I0 = issame args, nil
   if $I0 goto end
   $S0 = typeof args
   unless $S0 == 'Cons' goto rest_arg
   $P3 = car(args)
   $S0 = typeof $P3
   unless $S0 == 'Symbol' goto not_a_sym
   $P4 = new 'ArgInfo'
   setattribute $P4, 'sym', $P3
   $P5 = new 'String'
   $P5 = 'normal'
   setattribute $P4, 'type', $P5
   $P5 = uniq() # gensyms are valid parameter names
   $S0 = $P5 # conversion
   $P5 = new 'String'
   $P5 = $S0
   setattribute $P4, 'rep', $P5
   push into, $P4
   args = cdr(args) # advance
   goto loop
not_a_sym:
   ## try to see if it is an optional argument: (o name value)
   ## !! not working
   unless $S0 == 'Cons' goto arg_err
   $P0 = car(args)
   $S0 = typeof $P0
   unless $S0 == 'Symbol' goto arg_err
   $S0 = $P0
   unless $S0 == "o" goto arg_err
   $P0 = cdr(args)
   $S1 = typeof $P0
   unless $S1 == 'Cons' goto arg_err
   $P1 = car($P0)
   $S1 = typeof $P1
   unless $S1 == 'Symbol' goto arg_err
   $P3 = new 'ArgInfo'
   setattribute $P3, 'sym', $P1
   $P1 = new 'String'
   $P1 = "optional"
   setattribute $P3, 'type', $P1
   $P1 = uniq()
   $S0 = $P1
   $P1 = new 'String'
   $P1 = $S0
   setattribute $P3, 'rep', $P1
   $P1 = cdr($P0)
   $I0 = issame $P1, nil
   if $I0 goto ok
   $S1 = typeof $P1
   if $S1 == 'Cons' goto ok
   goto arg_err
ok:	
   $P1 = car($P1) # the value
   setattribute $P3, 'value', $P1
   push into, $P3
   args = cdr(args)
   goto loop
rest_arg:
   $S1 = typeof args
   unless $S1 == 'Symbol' goto arg_err
   $P4 = new 'ArgInfo'
   setattribute $P4, 'sym', args
   $P5 = new 'String'
   $P5 = 'rest'
   setattribute $P4, 'type', $P5
   $P5 = uniq() # gensyms are valid parameter names
   $S0 = $P5 # conversion
   $P5 = new 'String'
   $P5 = $S0
   setattribute $P4, 'rep', $P5
   push into, $P4
end:	
   .return ()
arg_err:
   die "Wrong argument format!"
   .return ()   
.end

## Traverse an expression. If a (fn ...) form is found, it is
## substituted with a ($closure ...) form. (fn ...) are collected in an
## array together with other informations, transformed in
## ($fn ...) forms and returned together with the new expression
## also collects constant values (quoted expressions, strings, etc.)
## Since we're already traversing the program, we macroexpand it
.sub _collect_fn_and_consts
   .param pmc expr
   .param pmc lex # list of lexicals so far
   .param pmc outer # name of outer function
   .param int is_seq # is the list passed a sequence of expressions ?
   .local pmc old_outer
   .local pmc new_expr
   .local pmc fns
   .local pmc consts
   .local pmc body
   .local pmc fn

   new_expr = expr
   fns = new 'ResizablePMCArray'
   consts = new 'ResizablePMCArray'
   
   $S0 = typeof expr
   if $S0 == 'Integer' goto const
   if $S0 == 'Float' goto const
   if $S0 == 'String' goto const
   unless $S0 == 'Cons' goto end
   ## if it is a sequence of expressions it cannot be a quote or a fn
   if is_seq goto for_each_init
   ## consider the first element
   $P0 = car(expr)
   $S0 = typeof $P0
   unless $S0 == 'Symbol' goto for_each_init
   $S0 = $P0 # conversion
   if $S0 == "quote" goto quote_const
   if $S0 == "fn" goto found1
   $I0 = _is_mac(expr) # could this be a macro?
   if $I0 goto expand_mac
   #expr = cdr(expr)
   goto for_each_init
expand_mac:
   ## macroexpansion
   $S0 = car(expr)
   $P0 = get_hll_global $S0 # get the value
   $P0 = rep($P0) # macro function
   $P1 = cdr(expr) # args
   $P1 = _list_to_array($P1)
   $P1 = arcall($P0, $P1 :flat) # call the macro
   .tailcall _collect_fn_and_consts($P1, lex, outer, 0) # call on the result
found1:	
   ## add one function
   fn = new 'FnInfo'
   $P0 = new 'String'
   $P0 = outer
   setattribute fn, 'outer', $P0
   $P0 = intern("$fn")
   $P1 = intern("$closure")
   $P2 = cdr(expr)
   $S0 = typeof $P2
   unless $S0 == 'Cons' goto malformed_function
   $P3 = car($P2) # fn's args
   lex = clone lex # will expand soon
   _collect_names($P3, lex) # expand array of declared vars
   setattribute fn, 'lex', lex
   body = cdr($P2)
   old_outer = outer
   outer = uniq() # name of fn (also the new outer)
   ($P4, $P5, body) = _collect_fn_and_consts(body, lex, outer, 1)
   _extend(fns, $P4)
   _extend(consts, $P5)
   $P3 = car($P2) # (arg1 ...)
   $P3 = cons($P3, body) # ((arg1 ...) body)
   $P3 = cons(outer, $P3) # (name (arg1 ...) body)
   $P3 = cons($P0, $P3) # ($fn name (arg1 ...) body)
   setattribute fn, 'expr', $P3 # function expression
   push fns, fn
   ## build ($closure ...) or ($function ...) form
   unless old_outer == "" goto build_it # not outer function?
   $P1 = intern("$function") # build a function, not a closure
build_it:	
   $P2 = get_hll_global 'nil'
   new_expr = cons(outer, $P2) # (name)
   new_expr = cons($P1, new_expr) # ($closure|$function name)
   .return (fns, consts, new_expr)
for_each_init:
   ## call on every element
   .local pmc last # last cons cell
   .local pmc nil
   nil = get_hll_global 'nil'
   last = nil
   new_expr = nil
for_each:
   $S0 = typeof expr
   unless $S0 == 'Cons' goto end # list finished
   $P0 = car(expr)
   ($P1, $P2, $P3) = _collect_fn_and_consts($P0, lex, outer, 0) # array of sub-expression
   _extend(fns, $P1) # extend fns with sub-expression's fn list
   _extend(consts, $P2)
next:
   ## append element to the end of the list
   $I0 = issame last, nil
   if $I0 goto first_elem
   $P4 = cons($P3, nil)
   scdr(last, $P4)
   last = cdr(last)
   goto end_if
first_elem:
   last = cons($P3, nil)
   new_expr = last
end_if:	
   expr = cdr(expr)
   goto for_each
end:
   .return (fns, consts, new_expr)
malformed_function:
   die "Malformed function!"
   .return (0)
const:
   ## add constant value
   $P0 = uniq() # the global name
   $P1 = new 'ConstInfo'
   setattribute $P1, 'expr', expr
   setattribute $P1, 'name', $P0
   push consts, $P1
   .return (fns, consts, $P0)
quote_const:
   $P0 = cdr(expr)
   $S0 = typeof $P0
   unless $S0 == 'Cons' goto malformed_quote
   $P1 = cdr($P0)
   $P2 = get_hll_global 'nil'
   $I0 = issame $P1, $P2
   unless $I0 goto malformed_quote
   $P0 = car($P0)
   $P1 = new 'ConstInfo'
   $P2 = uniq()
   setattribute $P1, 'expr', $P0
   setattribute $P1, 'name', $P2
   push consts, $P1
   .return (fns, consts, $P2)
malformed_quote:
   die "Malformed quote expression!"
   .return (0)
.end

## add every element of array b to array a
.sub _extend
   .param pmc a
   .param pmc b
   
   $P0 = new 'Iterator', b
loop:
   unless $P0 goto end
   $P1 = shift $P0
   push a, $P1
   goto loop
end:
   .return ()
.end

## tells if the passed expression refers to a macro
.sub _is_mac
   .param pmc expr
   .local pmc sym

   $S0 = typeof expr
   unless $S0 == 'Cons' goto fail
   sym = car(expr)
   $S0 = typeof sym
   unless $S0 == 'Symbol' goto fail
   $S0 = sym
   $P0 = get_hll_global $S0
   if_null $P0, fail # is this a defined global var?
   $S0 = typeof $P0
   unless $S0 == 'Tagged' goto fail
   $S0 = $P0[0] ## !! should use a more generic 'type function, when available
   unless $S0 == 'mac' goto fail
   .return (1)
fail:
   .return (0)
.end

.sub _emit_check_defined
   .param pmc code
   .param string reg
   .param string var_name

   $S0 = uniq()
   code.'emit'("unless_null %0, %1", reg, $S0)
   code.'emit'("$S0 = \"Unbound variable: %0\"", var_name)
   code.'emit'("'err'($S0)")
   code.'emit'("%0:", $S0)

   .return ()
.end
