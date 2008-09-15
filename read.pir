.HLL 'Arc', ''

.namespace [ ]

.const string separators = " \n\t" 
.const string special = ";()[]`,'"

.sub _init :load :init :anon
.end

.sub _skip_line
   .param pmc stream
loop:
   S0 = read stream, 1
   unless S0 == "\n" goto loop
.end

.sub _read_symbol
   .param pmc stream
   .local string result
   .local string sep
   .local string spec

loop:
   S0 = read stream, 1
   I0 = index separators, S0
   if I0 == -1 goto end
   I0 = index special, S0
   if I0 == -1 goto end
   result .= S0
   goto loop
end:
   P0 = new 'String'
   P0 = result
   .return intern(P0)
.end

#.sub _read_num
