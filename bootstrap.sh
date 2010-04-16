#!/bin/bash

# TODO: move in the makefile

PARROT='parrot -Xsrc/ops'

echo " eof" > /tmp/newline-file
cat compiler/boot.arc /tmp/newline-file | nc localhost 4321 > ac/boot.pir;
$PARROT -o ac/boot.pbc ac/boot.pir
cat compiler/comp.arc /tmp/newline-file | nc localhost 4321 > ac/comp.pir;
$PARROT -o ac/comp.pbc ac/comp.pir
cat arc/qq.arc /tmp/newline-file | nc localhost 4321 > ac/qq.pir;
$PARROT -o ac/qq.pbc ac/qq.pir

make && make primitivearc
