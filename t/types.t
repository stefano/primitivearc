#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use lib qw( . lib ../lib ../../parrot/lib ../parrot/lib );

use Test::More tests => 8;
use Parrot::Test;

# lists 
language_output_is('Arc', '(car nil)', "nil\n", 'list op');
language_output_is('Arc', '(cdr nil)', "nil\n", 'list op');
language_output_is('Arc', "(car '(1 2))", "1\n", 'list op');
language_output_is('Arc', "(cdr '(1 2))", "(2)\n", 'list op');
language_output_is('Arc', "(car (cdr (car '((1 2 . 3)))))", "2\n", 'list op');
language_output_is('Arc', '(cons 1 nil)', "(1)\n", 'list op');
language_output_is('Arc', '(car (cons 1 2))', "1\n", 'list op');
language_output_is('Arc', '(cdr (cons (cons 1 2) 3))', "3\n", 'list op');

