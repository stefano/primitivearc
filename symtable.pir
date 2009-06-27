.HLL 'Arc'

.namespace [ ]

.sub _init_symtable :anon :init :load

   ## global symbol table
   
   $P0 = new 'Hash'
   set_hll_global 'symbol-table', $P0
   $P0 = new 'Integer'
   $P0 = 0
   set_hll_global 'gensym-count', $P0
   
   .return ()
.end

.sub intern
   .param pmc str

   $P0 = get_hll_global 'symbol-table'
   $I0 = exists $P0[str]
   if $I0 goto exst
   $P1 = new 'ArcSym'
   $P1.'set_repr'(str)
   $P0[str] = $P1
   goto end

exst:
   $P1 = $P0[str]

end:
   .return ($P1)
.end

## return unique, not interned name
.sub uniq
   $P0 = get_hll_global 'gensym-count'
   $S0 = $P0
   $S1 = "gs"
   $S1 .= $S0
	 $S1 .= "_"
	 $I0 = time
	 $S0 = $I0
	 $S1 .= $S0
   $P0 += 1
   set_hll_global 'gensym-count', $P0
   $P1 = new 'ArcSym'
   $P1.'set_repr'($S1)
   .return ($P1)
.end
