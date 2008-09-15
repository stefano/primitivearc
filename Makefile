# put here the path to your parrot executable
PARROT=~/parrot/parrot

all: types.pbc symtable.pbc read.pbc arc.pbc 

types.pbc: types.pir
	$(PARROT) -o types.pbc types.pir

symtable.pbc: symtable.pir
	$(PARROT) -o symtable.pbc symtable.pir

read.pbc: read.pir
	$(PARROT) -o read.pbc read.pir

arc.pbc: arc.pir
	$(PARROT) -o arc.pbc arc.pir

clean:
	rm *.pbc *?~
