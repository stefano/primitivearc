.HLL 'Arc'

.namespace [ ]

.const string separators = " \n\t" 
.const string special = ";()[]`,'"
.const string specandsep = " \n\t;()[]`,'"

## ReadStream is a class containing the string to read from and the
## next position in the string to read

.sub '_init' :load :init :anon

   ## ReadStream class
   $P0 = subclass 'String', 'ReadStream'
   addattribute $P0, 'position'

   ## Global read table. Maps characters to functions
   $P0 = new 'Hash'
   $P1 = get_hll_global '_read_num'
   $P0["."] = $P1
   $P0["-"] = $P1
   $P0["0"] = $P1
   $P0["1"] = $P1
   $P0["2"] = $P1
   $P0["3"] = $P1
   $P0["4"] = $P1
   $P0["5"] = $P1
   $P0["6"] = $P1
   $P0["7"] = $P1
   $P0["8"] = $P1
   $P0["9"] = $P1
   $P1 = get_hll_global '_read_char'
   $P0["#"] = $P1
   $P1 = get_hll_global '_read_string'
   $P0["\""] = $P1
   $P1 = get_hll_global '_read_list'
   $P0["("] = $P1
   $P1 = get_hll_global '_read_quote'
   $P0["'"] = $P1
   $P1 = get_hll_global '_read_square_bracket'
   $P0["["] = $P1
   $P1 = get_hll_global '_read_qq'
   $P0["`"] = $P1
   $P1 = get_hll_global '_read_unquote'
   $P0[","] = $P1
   set_hll_global 'read-table*', $P0

   ## Global escape table
   $P0 = new 'Hash'
   $P0["n"] = "\n"
   $P0["t"] = "\t"
   $P0["\\"] = "\\"
   $P0["\""] = "\""
   set_hll_global 'escape-table*', $P0

   ## Global character names table
   $P0 = new 'ArcHash'
   $P0["newline"] = "\n"
   $P0["space"] = " "
   $P0["tab"] = "\t"
   set_hll_global 'char-table*', $P0
   
   ## Global ssyntax table
   ## each function take the string representation of the symbol
   ## and the position of the ssyntax character
   $P0 = new 'Hash'
   $P1 = get_hll_global '_ssyntax_neg'
   $P0["~"] = $P1
   $P1 = get_hll_global '_ssyntax_compose'
   $P0[":"] = $P1
   $P1 = get_hll_global '_ssyntax_dot'
   $P0["."] = $P1
   $P1 = get_hll_global '_ssyntax_exclamation'
   $P0["!"] = $P1
   set_hll_global 'ssyntax-table*', $P0
   
   .return ()
.end

.namespace ['ReadStream']

.sub 'input' :method
   .param string str
   
   self = str # stream contents
   $P0 = new 'ArcInt'
   $P0 = 0
   setattribute self, 'position', $P0 # start at position 0

   .return (self)
.end

## signals eof only _after_ reading one char beyond the last
.sub 'is_eof' :method
   $P0 = getattribute self, 'position'
   $I0 = $P0
   $S0 = self
   $I1 = length $S0
   if $I0 <= $I1 goto false
   .return (1)
false:
   .return (0)
.end

.sub 'peek1' :method
   $P0 = getattribute self, 'position'
   $I0 = $P0
   $S0 = self
   $I1 = length $S0
   if $I0 >= $I1 goto end
   $S0 = self[$I0]
   .return ($S0)
end:
   $P0 = get_hll_global 'nil'
   .return ($P0)
.end

## get next character and advance position
## return nil on end-of-string
.sub 'get1' :method
   $P0 = getattribute self, 'position'
   $I0 = $P0
   $S0 = self
   $I1 = length $S0
   if $I0 >= $I1 goto stream_end
   $S1 = self[$P0]
   $P0 += 1
   setattribute self, 'position', $P0
   .return ($S1)
stream_end:
   $P0 = get_hll_global 'nil'
   .return ($P0)
.end

.namespace [ ]

## get characters until end-of-stream or a character in the given list is found
.sub 'get_upto'
   .param pmc rs
   .param string stoppers # tells if we need to stop reading
   .local string res
   .local pmc nil

   nil = get_hll_global 'nil'
   res = ""
   
loop:
   $P0 = rs.'peek1'()
   $I0 = issame nil, $P0
   if $I0 goto end
   $S0 = $P0
   $I0 = index stoppers, $S0
   unless $I0 == -1 goto end
   res .= $S0
   rs.'get1'()
   goto loop
end:
   .return (res)
.end
   
## main reader function
.sub '_read'
   .param pmc rs
   .local pmc tbl

   tbl = get_hll_global 'read-table*'
start:	
   _skip_separators(rs)
   $I0 = rs.'is_eof'()
   if $I0 goto eof_found
   $S0 = rs.'peek1'()
   unless $S0 == ";" goto keep_going
   ## handle a comment
   _skip_line(rs)
   goto start
keep_going:
   $P0 = tbl[$S0]
   $I0 = defined $P0
   unless $I0 goto default
   .tailcall $P0(rs)
default:
   ## if the character isn't present in the read table, read a symbol
   .tailcall _read_symbol(rs)
eof_found:      
   $P0 = new 'Eof'
   .return ($P0)
.end

.sub '_skip_line'
   .param pmc rs
loop:
   $S0 = rs.'get1'()
   unless $S0 == "\n" goto loop
.end

.sub '_skip_separators'
   .param pmc rs

loop:	
   $S0 = rs.'peek1'()
   $I0 = index separators, $S0
   if $I0 == -1 goto end
   rs.'get1'() # throw away
   $I0 = rs.'is_eof'()
   if $I0 goto end
   goto loop
end:
   .return ()
.end

.sub '_read_symbol'
   .param pmc rs
   .local string result

   result = ""
   
loop:
   $P0 = rs.'peek1'()
	 $S0 = $P0.'pr_repr'()
   if $S0 == 'nil' goto end # EOF
   $I0 = index separators, $S0
   unless $I0 == -1 goto end # separator may be safely left in the stream
   $I0 = index special, $S0
   unless $I0 == -1 goto end # special character will be needed later
   result .= $S0
   rs.'get1'() # advance
   goto loop
end:
   ## !! should handle null symbol?
   ## handle the constants t & nil
   if result == "t" goto ret_t
   if result == "nil" goto ret_nil
   $P0 = 'intern'(result)
   .tailcall 'ssexpand'($P0)
ret_t:
   $P0 = get_hll_global 't'
   .return ($P0)
ret_nil:
   $P0 = get_hll_global 'nil'
   .return ($P0)
.end

## check if a string contains only of a certain set of character
## at least one must be present
.sub '_str_made_of'
   .param string in
   .param string allowed
   .param int from

   $I0 = from
   $I1 = length in
   if from >= $I1 goto fail
loop:	
   if $I0 >= $I1 goto ok
   $S0 = substr in, $I0, 1
   $I2 = index allowed, $S0
   if $I2 == -1 goto fail
   $I0 += 1
   goto loop
ok:
   .return (1)
fail:
   .return (0)
.end

## try to read a number, but if it can't parse it as a number, return a
## symbol
## ?? could _read_num substitute _read_symbol? ?? 
.sub '_read_num'
   .param pmc rs
   .local int from

   ## read it
   $S0 = 'get_upto'(rs, specandsep)
   ## if it is parsed as a number, from will be 0 if it is positive,
   ## 1 if it isn't: it will mark the first digit position
   from = index $S0, "-"
   from += 1
   ## check if it has one '-' not at the beginning
   $I0 = index $S0, "-", 1
   unless $I0 == -1 goto mk_symbol
   ## check if it is a float
   $I0 = index $S0, "."
   if $I0 == -1 goto try_integer # no dot found
   ## has it two dots ?
   $I0 += 1
   $I0 = index $S0, ".", $I0
   unless $I0 == -1 goto mk_symbol # if it has two dots, it's a symbol
   ## check if it has only digits (except for the dot and minus sign)
   $I0 = _str_made_of($S0, "0123456789.", from)
   unless $I0 goto mk_symbol
   ## now we're sure we've got a float
   $P0 = new 'ArcNum'
   $N0 = $S0 # type conversion
   $P0 = $N0
   .return ($P0)
try_integer:
   ## try to parse an int
   $I0 = _str_made_of($S0, "0123456789", from)
   unless $I0 goto mk_symbol
   $P0 = new 'ArcInt'
   $I0 = $S0 # type conversion
   $P0 = $I0
   .return ($P0)
mk_symbol:
   $P0 = 'intern'($S0)
   .tailcall 'ssexpand'($P0)
.end

.sub '_read_char'
   .param pmc rs
   .local pmc ct

   ct = get_hll_global 'char-table*'
   rs.'get1'() # skip #
   $S0 = rs.'get1'()
   unless $S0 == "\\" goto error
   $P0 = _read_symbol(rs)
   $S0 = $P0.'to_string'() # get char name
   $S1 = ct[$S0]
   unless $S1 == "" goto ret_it
   $I0 = length $S0
   unless $I0 == 1 goto error
	 $P0 = new 'ArcChar'
	 $P0 = $S0
   .return ($P0)
ret_it:
	 $P1 = new 'ArcChar'
	 $P1 = $S1
   .return ($P1)
error:
   .tailcall 'err'("Wrong syntax")
.end

.sub '_read_string'
   .param pmc rs
   .local string res
   .local int escapep # true when we need to escape a character
   .local pmc esc

   res = ""
   escapep = 0
   esc = get_hll_global 'escape-table*'
   
   rs.'get1'() # skip "
loop:
   $S0 = rs.'get1'() # no check for end-of-string...
   unless escapep goto end_escape
   escapep = 0
   $S0 = esc[$S0]
   unless $S0 goto error
   res .= $S0
   goto loop
end_escape:
   unless $S0 == "\\" goto end_start_escape
   escapep = 1
   goto loop
end_start_escape:
   if $S0 == "\"" goto end
   res .= $S0
   goto loop
end:
   .return (res)
error:
   die "Cannot escape char"
   .return ("")
.end

## read a list terminating with ter
## suppose opening bracket already read
.sub '_read_list_with_ter'
   .param pmc rs
   .param string ter
  
   _skip_separators(rs)
   $S0 = rs.'peek1'()
   if $S0 == ter goto end # list terminated
   $P0 = _read(rs) # read the car
   _skip_separators(rs)
   $S0 = rs.'peek1'()
   if $S0 == "." goto dotted_list # a dotted list ( --- . - )
   if $S0 == ter goto ter_found
   ## start of another element
   $P1 = _read_list_with_ter(rs, ter)
   .tailcall cons($P0, $P1)
dotted_list:
   rs.'get1'() # throw away '.'
   $P1 = _read(rs) # read the cdr
   _skip_separators(rs)
   $S0 = rs.'get1'()
   unless $S0 == ter goto error # only one object may follow the dot
   .tailcall cons($P0, $P1)
ter_found:
   rs.'get1'() # throw away terminator
   $P1 = get_hll_global 'nil'
   .tailcall cons($P0, $P1)
end:
   rs.'get1'() # throw away terminator 
   $P0 = get_hll_global 'nil'
   .return ($P0)
error:
   die "More than one object follows ."
   $P0 = get_hll_global 'nil'
   .return ($P0)
.end
   
.sub '_read_list'
   .param pmc rs

   rs.'get1'() # skip (
   .tailcall _read_list_with_ter(rs, ")")
.end

.sub '_read_square_bracket'
   .param pmc rs

   rs.'get1'() # skip [
   $P0 = _read_list_with_ter(rs, "]") # expr
   $P1 = intern("fn")
   $P2 = intern("_")
   $P3 = get_hll_global 'nil'
   $P2 = cons($P2, $P3) # (_)
   $P0 = cons($P0, $P3) # (expr)
   $P2 = cons($P2, $P0) # ((_) expr)
   .tailcall cons($P1, $P2) # (fn (_) expr)
.end

.sub '_read_next_with_head'
   .param pmc rs
   .param string head
   
   $P0 = _read(rs) # expr
   $P1 = intern(head)
   $P2 = get_hll_global 'nil'
   $P0 = cons($P0, $P2) # (expr)
   .tailcall cons($P1, $P0) # (head expr)
.end

.sub '_read_quote'
   .param pmc rs
   rs.'get1'() # skip '
   .tailcall _read_next_with_head(rs, "quote")
.end

.sub '_read_qq'
   .param pmc rs
   rs.'get1'() # skip `
   .tailcall _read_next_with_head(rs, "quasiquote")
.end

.sub '_read_unquote'
   .param pmc rs
   .local string type
   
   type = "unquote"
   rs.'get1'() # skip ,
   $S0 = rs.'peek1'()
   unless $S0 == '@' goto go_on
   type = "splice"
   rs.'get1'() # throw away '@'
go_on:
   .tailcall _read_next_with_head(rs, type)
.end

.include 'types_macros.pir'

.sub 'ssexpand'
   .param pmc sym

   .check_type(sym, 'sym')
   .local pmc tbl
   tbl = get_hll_global 'ssyntax-table*'
   $I0 = -1
   $S0 = sym.'to_string'()
   $I1 = length $S0
loop:
   $I0 = $I0 + 1
   if $I0 == $I1 goto end
   $S1 = substr $S0, $I0, 1
   $P0 = tbl[$S1]
   $I2 = defined $P0
   unless $I2 goto loop
   .tailcall $P0($S0, $I0)
end:
   .return (sym)
.end

.sub '_ssyntax_neg'
   .param string sym
   .param int pos

   if pos == 0 goto ok
   .tailcall 'intern'(sym)

ok:     
   $S0 = substr sym, 1
   $P0 = 'intern'("complement")
	 $P1 = 'instring'($S0)
	 $P1 = 'read'($P1)
   .tailcall 'list'($P0, $P1)
.end

## check that the ssyntax character is in the middle of the symbol
## and return the two (expanded) sides
.sub '_get_sides'
   .param string sym
   .param int pos

   $I0 = length sym
   $I0 = $I0 - 1
   if pos == 0 goto error
   if pos == $I0 goto error
   $S0 = substr sym, 0, pos
   $I0 = pos + 1
   $S1 = substr sym, $I0
	 $P0 = 'instring'($S0)
	 $P0 = 'read'($P0)
	 $S0 = $P0.'to_string'()

	 $P1 = 'instring'($S1)
	 $P1 = 'read'($P1)

   .return ($P0, $P1)
error:
   .tailcall 'err'("Wrong usage of ssyntax")
.end

.sub '_ssyntax_compose'
   .param string sym
   .param int pos
   $P0 = 'intern'("compose")
   ($P1, $P2) = _get_sides(sym, pos)
   .tailcall 'list'($P0, $P1, $P2)
.end

.sub '_ssyntax_dot'
   .param string sym
   .param int pos
   ($P0, $P1) = _get_sides(sym, pos)
   .tailcall 'list'($P0, $P1)
.end

.sub '_ssyntax_exclamation'
   .param string sym
   .param int pos
   ($P0, $P1) = _get_sides(sym, pos)
   $P2 = 'intern'("quote")
   $P1 = 'list'($P2, $P1)
   .tailcall 'list'($P0, $P1)
.end
