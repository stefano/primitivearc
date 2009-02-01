#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use lib qw( . lib ../lib ../../lib );

use Test::More tests => 9;
use Parrot::Test;

## tests for builtin functions

language_output_like('Arc', '(err "ho")', 'Error', 'err');
language_output_is('Arc', '(is (uniq) (uniq))', "nil\n", 'uniq');
language_output_is('Arc', '(type (uniq))', "sym\n", 'uniq');

## file input
language_output_is('Arc', << 'CODE', << 'RES', 'infile & readc');
(set in (infile "file_test.txt"))
(set c1 (readc in))
(set c2 (readc in))
(close in)
(write c1)
c2
CODE
#\O
#\K
RES

language_output_is('Arc', << 'CODE', << 'RES', 'infile & readb');
(set in (infile "file_test.txt"))
(set c1 (readb in))
(set c2 (readb in))
(close in)
(write c1)
c2
CODE
#\O
#\K
RES

language_output_is('Arc', << 'CODE', << 'RES', 'infile & peekc');
(set in (infile "file_test.txt"))
(set c1 (peekc in))
(set c2 (peekc in))
(close in)
(write c1)
c2
CODE
#\O
#\O
RES

## full read functionality not tested here. just check it works on files
language_output_is('Arc', << 'CODE', << 'RES', 'infile & read');
(set in (infile "file_test.txt"))
(set s (read in))
(close in)
s
CODE
OK
RES

language_output_is('Arc', << 'CODE', << 'RES', 'infile & call-w/stdin');
(set in (infile "file_test.txt"))
(set s (call-w/stdin in read))
(close in)
s
CODE
OK
RES

## echo must be present (likely to fail on Windows systems)
language_output_is('Arc', << 'CODE', << 'RES', 'pipe-from');
(set in (pipe-from "echo \"a\""))
(set s (read in))
(close in)
s
CODE
a
RES
