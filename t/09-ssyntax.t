#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use lib qw( . lib ../lib ../../lib );

use Test::More tests => 8;
use Parrot::Test;

## [ ... ]
language_output_is('Arc', '([+ _ 1] 9)', "10\n", '[ ... ]');
language_output_is('Arc', '([+ (- _) 1] 9)', "-8\n", '[ ... ]');

## .
language_output_is('Arc', '(assign f (list 1 2)) f.1', "2\n", 'x.y');
language_output_is('Arc', '(assign f (fn (x) x)) f."abc"', "\"abc\"\n", 'x.y');

## !
language_output_is('Arc', '(assign f (list 1 2)) f!1', "2\n", 'x!y');

## :
language_output_is('Arc', '(assign f (list 1 2)) (assign g (fn (x) (+ x 1))) (g:f 1)', "3\n", 'x:y');

## ~
language_output_is('Arc', '(~is 1 1)', "nil\n", "~is");
language_output_is('Arc', '~is.1', "nil\n", "~is.1");
