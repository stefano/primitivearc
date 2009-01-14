.macro check_type(obj, expected)
   .local string __type
   __type = typeof .obj
   if __type == .expected goto .$a
   $S0 = "Type error: expected "
   $S0 .= .expected
   $S0 .= " but got "
   $S0 .= __type
   .tailcall 'err'($S0)
   .label $a:
.endm
