#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use lib qw( . lib ../lib ../../lib );

use Test::More tests => 8;
use Parrot::Test;

language_output_is('Arc', '(fn ())', "#<function>\n", "simple fn");
language_output_is('Arc', '((fn (x) x) 9)', "9\n", "id fn");
language_output_is('Arc', '((fn (x y) y) 1 2)', "2\n", "2 args fn");
language_output_is('Arc', '((fn r r) 1 2 3)', "(1 2 3)\n", "rest arg fn");
language_output_is('Arc', '((fn (x . r) x) 0 1 2)', "0\n", "arg + rest fn");
language_output_is('Arc', '((fn (x . r) r) 0 1 2)', "(1 2)\n", "arg + rest fn");
language_output_is('Arc', '((fn (f x y) (+ (f x) y)) (fn (x) (+ x 1)) 1 2)', "4\n", "fn that takes a fn");
language_output_is('Arc', '(set f (fn (x) (fn () (set x (+ x 1))))) (set g (f 1)) (set h (f 1)) (g) (h) (h)', "3\n", "simple closure")
