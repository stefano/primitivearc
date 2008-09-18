.HLL 'Arc', ''

.sub _init :anon :load :init

   ## class holding information needed by compilation
   P0 = newclass 'CompilerState'
   addattribute P0, 'code' # CodeString of code emitted so far
   addattribute P0, 'lex' # list of lexical variables
   addattribute P0, 'nextreg' # number of next free register to use

   .return ()
.end

.namespace [ 'CompilerState' ]

## get name of next free register
.sub _next_reg :method
   P0 = getattribute self, 'nextreg'
   P0 += 1
   setattribute self, 'nextreg', P0

   S0 = '$P'
   S1 = P0
   S0 .= S1
   .return (S0)
.end

## mark all registers as free
.sub _reset_reg :method
   P0 = getattribute self, 'nextreg'
   P0 = 0
   setattribute self, 'nextreg', P0
   .return ()
.end

## mark last allocated register as free, return freed register name
.sub _free_reg :method
   P0 = getattribute self, 'nextreg'
   S0 = '$P'
   S1 = P0
   S0 .= S1
   P0 -= 1
   setattribute self, 'nextreg', P0
   .return (S0)
.end

## simulate a push on a stack using registers, return reg name
.sub _push :method
   .return self.'_next_reg'()
.end

## simulate a pop, return register name with value
## use the value before a push is made!
.sub _pop :method
   .return self.'_free_reg'()
.end

.namespace [ ]

## create a new empty CompilerState
.sub _empty_state
   P0 = new 'CompilerState'
   P1 = new 'CodeString'
   setattribute P0, 'code', P1
   P1 = new 'ResizableStringArray'
   setattribute P0, 'lex', P1
   P1 = new 'Integer'
   P1 = 0
   setattribute P0, 'nextreg', P1

   .return (P0)
.end

.sub _lexical
   .param pmc lst
   .param pmc sym

   P0 = new 'Iterator', lst
loop:
   unless P0 goto no
   P1 = shift P0
   I0 = issame sym, P1
   if I0 goto yes
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

   .local pmc code
   .local string type
   .local string out_reg
   code = getattribute cs, 'code'
   type = typeof expr
   out_reg = cs.'_push'() # output register

   if type == 'String' goto str
   if type == 'Integer' goto int_num
   if type == 'Float' goto float_num
   if type == 'Symbol' goto var_ref
   if type == 'Cons' goto special_or_call
   
   ## unknown expression
   die "Unknown expression"
   .return ()

str:
   S1 = code.'escape'(expr) # value
   code.'emit'("%0 = new 'String'\n", out_reg)
   code.'emit'("%0 = %1\n", out_reg, S1)
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
   P0 = getattribute cs, 'lex'
   I0 = _lexical(P0, expr)
   if I0 goto lex
   ## ?? should escape symbol? the only character that could create
   ## ?? problems is ', and it won't appear in a symbol once
   ## ?? quoting is implemented
   code.'emit'("%0 = get_hll_global '%1'", out_reg, expr)
   .return ()
lex:
   code.'emit'("%0 = find_lex '%1'", out_reg, expr)
   .return ()
special_or_call:
   P0 = car(expr)
   S0 = typeof P0
   unless S0 == 'Symbol' goto is_call
   S0 = P0
   if S0 == '$fn' goto glob_fun
   if S0 == '$closure' goto new_closure
   goto is_call
glob_fun:	# global function declaration
   .return _compile_fn(cs, expr)
new_closure:	# closure creation
   .return _compile_closure(cs, expr)
is_call:
   .local pmc args # array holding function & arguments registers
   args = new 'ResizableStringArray'
   I0 = 0
args_loop:	# compile every argument
   S0 = typeof expr
   unless S0 == 'Cons' goto args_emitted
   P0 = car(expr)
   _compile_expr(cs, P0)
   I0 += 1
   expr = cdr(expr)
   goto args_loop
   ## put register names in args
args_emitted:
   if I0 == 0 goto end_args
   S0 = cs.'_pop'()
   unshift args, S0
   I0 -= 1
   goto args_emitted
end_args:
   code.'emit'("arcall(%,)\n", args :flat)
   .return ()
.end

.sub _emit_fn_head
   .param pmc cs
   .param string name
   .param int anon
   
   P0 = getattribute cs, 'code'
   S0 = ""
   unless anon goto go_on
   S0 = ":anon"
go_on:	
   P0.'emit'(".sub %0 %0\n", name, S0)

   .return ()
.end

## emit a sequence of operations
.sub _compile_seq
   .param pmc cs
   .param pmc seq

   .local pmc nil
   .local int cons_type
   nil = get_hll_global 'nil'
   cons_type = find_type 'Cons'
   
   P0 = seq 
loop:
   I0 = issame seq, nil
   if I0 goto end # list finished
   I0 = typeof seq
   unless I0 == cons_type goto error # dotted list?
   P1 = car(P0) # expression to compile
   _compile_expr(cs, P0)
   P0 = cdr(P0) # advance
   I0 = issame P0, nil
   if I0 goto end # only last expression's value won't be ignored
   cs.'_pop'() # ignore return register of this expression
   goto loop
end:	
   .return ()
error:
   die "Sequence is not a proper list!"
   .return ()
.end

## compiles a function expression
## it must be at the global level
## ($fn name (arg1 ... . rest-arg) ...)
.sub _compile_fn
   .param pmc cs
   .param pmc expr
   
   P0 = cdr(expr)
   P0 = car(P0) # cadr: function name
   S0 = typeof P0
   unless S0 == 'Symbol' goto not_a_sym_err
   S0 = P0
   _emit_fn_head(cs, S0, 1) # always anonimous

   .local pmc code
   .local pmc new_lex
   .local pmc old_lex
   .local pmc nil
   .local int cons_type
   .local int sym_type

   code = getattribute cs, 'code'
   old_lex = getattribute cs, 'lex'
   new_lex = clone old_lex
   P2 = cdr(expr)
   P2 = cdr(P2)
   P2 = car(P2) # 3rd element: arg. list
   nil = get_hll_global 'nil'
   cons_type = find_type 'Cons'
   sym_type = find_type 'Symbol'
   ## for each name in arg. list, put it in new_lex
   ## and emit code for it
loop:
   I0 = issame P2, nil
   if I0 goto end
   I0 = typeof P2
   unless I0 == cons_type goto rest_arg
   P3 = car(P2)
   I0 = typeof P3
   unless I0 == sym_type goto not_a_sym_err
   push new_lex, P3 
   S0 = P3 # convert to string
   code.'emit'(".param pmc '%0'\n", S0)
   P2 = cdr(P2) # advance
   goto loop
rest_arg:
   I0 = typeof P2
   unless I0 == sym_type goto not_a_sym_err
   push new_lex, P2
   S0 = P2
   code.'emit'(".param pmc '%0' :slurpy\n", S0)
   ## !! we should convert slurpy array to cons list here
end:
   setattribute cs, 'lex', new_lex
   P0 = cdr(expr)
   P0 = cdr(P0)
   P0 = cdr(P0) # cdddr: the body
   cs.'_reset_reg'() # at the start of a function all regs are free
   _compile_seq(cs, P0)
   setattribute cs, 'lex', old_lex # restore lexical list
   code.'emit'(".end\n")
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

   P0 = cdr(expr)
   P0 = car(P0) # cadr: code-name
   S0 = P0
   .local pmc code
   code = getattribute cs, 'code'
   S1 = cs.'_push'()
   code.'emit'("%0 = get_hll_global '%1'\n", S1, S0) # get the global Sub
   code.'emit'("%0 = newclosure %0", S1) # create the closure
   .return ()
.end

## Traverse an expression. If a (fn ...) form is found, it is
## substituted (destructively) with a ($closure ...) form. (fn ...) are
## collected in an array, transformed in ($fn ...) forms and returned
.sub _collect_fn
   .param pmc expr
   .local pmc fns
   .local pmc name
   .local pmc body
   
   fns = new 'ResizablePMCArray'

   S0 = typeof expr
   unless S0 == 'Cons' goto end
   ## consider the first element
   P0 = car(expr)
   S0 = typeof P0
   unless S0 == 'Symbol' goto for_each
   S0 = P0 # conversion
   if S0 == "quote" goto end # quoted expressions should be ignored
   if S0 == "fn" goto found1
   expr = cdr(expr)
   goto for_each
found1:	
   ## add one function
   P0 = intern("$fn")
   P1 = intern("$closure")
   P2 = cdr(expr)
   S0 = typeof P2
   unless S0 == 'Cons' goto malformed_function
   body = cdr(P2) 
   name = uniq() # name of fn
   P3 = cons(name, P2) # (name (arg1 ...) body)
   P3 = cons(P0, P3) # ($fn name (arg1 ...) body)
   push fns, P3
   ## transform into call to ($closure ...)
   scar(expr, P1)
   P2 = get_hll_global 'nil'
   P4 = cons(name, P2) # (name)
   scdr(expr, P4) # expr = ($closure name)
   expr = body # set up to continue with for_each
   ## now call on every element
for_each:
   S0 = typeof expr
   unless S0 == 'Cons' goto end # list finished
   P0 = car(expr)
   P1 = _collect_fn(P0) # array of sub-expression
   I0 = P1 # length of the array
   if I0 == 0 goto next # no need to extend
   _extend(fns, P1) # extend fns with sub-expression's fn list
next:
   expr = cdr(expr)
   goto for_each
end:	
   .return (fns)
malformed_function:
   die "Malformed function!"
   .return (0)
.end

## add every element of array b to array a
.sub _extend
   .param pmc a
   .param pmc b
   
   P0 = new 'Iterator', b
loop:
   unless P0 goto end
   P1 = shift P0
   push a, P1
   goto loop
end:
   .return ()
.end
