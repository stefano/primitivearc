## builtin functions

.HLL 'Arc', ''

.sub err
   .param pmc what
   P0 = new 'String'
   P0 = "Error: "
   P0 .= what
   die P0
   .return (P0)
.end
