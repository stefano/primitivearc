#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use lib qw( . lib ../lib ../../lib );

use Test::More tests => 22;
use Parrot::Test;

# nil & t
language_output_is('Arc', 't', "t\n", 't');
language_output_is('Arc', 'nil', "nil\n", 'nil');
language_output_is('Arc', "(is t 't)", "t\n", 't');
language_output_is('Arc', "(is nil 'nil)", "t\n", 'nil');
language_output_is('Arc', "(is nil '())", "t\n", 'nil');
language_output_is('Arc', "(is nil t)", "nil\n", 't/nil');

# lists 
language_output_is('Arc', '(car nil)', "nil\n", 'list op');
language_output_is('Arc', '(cdr nil)', "nil\n", 'list op');
language_output_is('Arc', "(car '(1 2))", "1\n", 'list op');
language_output_is('Arc', "(cdr '(1 2))", "(2)\n", 'list op');
language_output_is('Arc', "(car (cdr (car '((1 2 . 3)))))", "2\n", 'list op');
language_output_is('Arc', '(cons 1 nil)', "(1)\n", 'list op');
language_output_is('Arc', '(car (cons 1 2))', "1\n", 'list op');
language_output_is('Arc', '(cdr (cons (cons 1 2) 3))', "3\n", 'list op');

# symbols
language_output_is('Arc', "'car", "car\n", 'sym');
language_output_is('Arc', "(set car 1) car", "1\n", 'sym');
language_output_is('Arc', '(intern "CkL")', "CkL\n", 'sym');

# annotations
language_output_is('Arc', "(annotate 2 1)", "#3(tagged 2 1)\n", 'annotations');
language_output_is('Arc', "(type (annotate 2 1))", "2\n", 'annotations');
language_output_is('Arc', "(rep (annotate 2 1))", "1\n", 'annotations');

# strings
language_output_is('Arc', '"a string"', "\"a string\"\n", 'strings');
language_output_is('Arc', '"a string\n"', "\"a string\n\"\n", 'strings');
