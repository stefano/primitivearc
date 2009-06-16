#!/bin/bash

ARC=/home/stefano/arc_github/arc/arc.sh
PARROT='./primitivearc -pir'
TMP=/tmp/parrot-tmp

cat $1 | $ARC compiler/tl.arc > $TMP;
$PARROT $TMP
