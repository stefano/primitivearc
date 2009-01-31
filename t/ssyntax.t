#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use lib qw( . lib ../lib ../../lib );

use Test::More tests => 7;
use Parrot::Test;

## [ ... ]
language_output_is('Arc', '([+ _ 1] 9)', "10\n", '[ ... ]');
language_output_is('Arc', '([+ (- _) 1] 9)', "-8\n", '[ ... ]');

## .
language_output_is('Arc', '(set f (list 1 2)) f.1', "2\n", 'x.y');
language_output_is('Arc', '(set f (fn (x) x)) f."abc"', "\"abc\"\n", 'x.y');

## !
language_output_is('Arc', '(set f (list 1 2)) f!1', "2\n", 'x!y');
language_output_is('Arc', '(set f (fn (x) x)) f!(1 2 3)', "(1 2 3)\n", 'x!y');

## :
language_output_is('Arc', '(set f (list 1 2)) (set g (fn (x) (+ x 1))) (g:f 1)', "3\n", 'x:y');
