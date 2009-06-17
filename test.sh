#!/bin/bash

ARC=/home/stefano/arc_github/arc/arc.sh
PARROT='./primitivearc -pir'
TMP=/tmp/parrot-tmp

echo " eof" > /tmp/newline-file
cat $1 /tmp/newline-file | nc localhost 4321 > $TMP;
#cat $1 | $ARC compiler/tl.arc > $TMP

$PARROT $TMP


