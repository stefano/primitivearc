.HLL 'Arc', ''

.namespace [ ]

.const string separators = " \n\t" 
.const string special = ";()[]`,'"
.const string specandsep = " \n\t;()[]`,'"

## ReadStream is a class containing the string to read from and the
## next position in the string to read

.sub _init :load :init :anon

   ## ReadStream class
   P0 = subclass 'String', 'ReadStream'
   addattribute P0, 'position'

   ## Global read table. Maps characters to functions
   P0 = new 'Hash'
   set_hll_global 'read-table*', P0

   ## Global escape table
   P0 = new 'Hash'
   set_hll_global 'escape-table*', P0

   .return ()
.end

.namespace ['ReadStream']

.sub __new_from_string
   .param pmc class
   .param string str
   .param int flags

   I0 = typeof class
   P0 = new I0
   P0 = str # stream contents
   P1 = new 'Integer'
   P1 = 0
   setattribute P0, 'position', P1 # start at position 0

   .return (P0)
.end


## go back one character
.sub back1 :method
   P0 = getattribute self, 'position'
   P0 -= 1
   setattribute self, 'position', P0

   .return ()
.end

## get next character and advance position
## return 0 on end-of-string
.sub get1 :method
   P0 = getattribute self, 'position'
   I0 = P0
   S0 = self
   I1 = length S0
   if I0 >= I1 goto stream_end
   P1 = self[P0]
   P0 += 1
   setattribute self, 'position', P0
   .return (P1)
stream_end:
   .return (0)
.end

## get characters until end-of-string or a character in the given list is found
.sub get_upto :method
   .param string stoppers # tells if we need to stop reading
   .local string res
   
   P0 = getattribute self, 'position'
   I0 = P0
   S0 = self
   I1 = length S0
   if I0 >= I1 goto end
loop:
   S0 = self[I0]
   I2 = index S0, stoppers
   unless I2 == -1 goto end # pos won't be incremented
   res .= S0
   I0 += 1
end:
   setattribute self, 'position', I0
   .return (res)
.end
   
.namespace [ ]

.sub _skip_line
   .param pmc rs
loop:
   S0 = rs.get1()
   unless S0 == "\n" goto loop
.end

.sub _read_symbol
   .param pmc rs
   .local string result
   .local string sep
   .local string spec

loop:
   S0 = rs.get1()
   I0 = index separators, S0
   if I0 == -1 goto end
   I0 = index special, S0
   if I0 == -1 goto retain1 # special character will be needed later
   result .= S0
   goto loop
retain1:
   rs.back1()
end:
   P0 = new 'String'
   P0 = result
   .return intern(P0)
.end

.sub _read_num
   .param pmc rs

   S0 = rs.get_upto(specandsep)
   P0 = new 'Number' # TODO: distinguish integer from floats
   P0 = S0 # type conversion string -> number

   .return (P0)
.end
   
.sub _read_string
   .param pmc rs
   .local string res
   .local int escapep # true when we need to escape a character
   .local pmc esc

   escapep = 0
   get_hll_global 'escape-table*', esc
   
   rs.get1() # skip "
loop:
   S0 = rs.get1() # no check for end-of-string...
   unless escapep goto end_escape
   escapep = 0
   S0 = esc[S0]
   unless S0 die "Cannot escape char"
end_escape:
   unless S0 == "\\" goto end_start_escape
   escapep = 1
   goto loop
end_start_escape:
   if S0 == "\"" goto end
   res .= S0
   goto loop
end:
   .return (res)
.end

