.HLL 'Arc', ''

.namespace [ ]

.sub _init_symtable :anon :init :load

   ## global symbol table
   
   P0 = new 'Hash'
   set_hll_global 'symbol-table', P0
   P0 = new 'Integer'
   P0 = 0
   set_hll_global 'gensym-count', P0
   
   .return ()
.end

.sub intern
   .param pmc str

   P0 = get_hll_global 'symbol-table'
   I0 = exists P0[str]
   if I0 goto exst
   P1 = new 'Symbol'
   P1 = 2
   P1[0] = str
   P2 = get_hll_global 'nil'
   P1[1] = P2
   P0[str] = P1
   goto end

exst:
   P1 = P0[str]

end:
   .return (P1)
.end

## return unique, not interned name
.sub uniq
   P0 = get_hll_global 'gensym-count'
   S0 = P0
   S1 = "gs"
   S1 .= S0
   P0 += 1
   set_hll_global 'gensym-count', P0
   P1 = new 'Symbol'
   P1 = 2
   P1[0] = S1
   P2 = get_hll_global 'nil'
   P1[1] = P2
   .return (P1)
.end
