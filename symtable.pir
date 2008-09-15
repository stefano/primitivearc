.HLL 'Arc', ''

.namespace [ ]

.sub _init_symtable :anon :init :load

   ## global symbol table
   
   P0 = new 'Hash'
   set_hll_global 'symbol-table', P0

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
