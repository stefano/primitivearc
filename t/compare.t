#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use lib qw( . lib ../lib ../../lib );

use Test::More tests => 51;
use Parrot::Test;

## is
language_output_is('Arc', '(is)', "t\n", 'empty is');
language_output_is('Arc', '(is nil)', "t\n", 'one arg is');
language_output_is('Arc', '(is nil nil)', "t\n", 'is');
language_output_is('Arc', '(is nil t)', "nil\n", 'is');
language_output_is('Arc', '(is 1 nil)', "nil\n", 'is');
language_output_is('Arc', '(is 1 t)', "nil\n", 'is');
language_output_is('Arc', '(is 1 1)', "t\n", 'is');
language_output_is('Arc', '(is 1 1.0)', "t\n", 'is');
language_output_is('Arc', '(is 1 1.1)', "nil\n", 'is');
language_output_is('Arc', '(is 2 1 2)', "nil\n", 'is');
language_output_is('Arc', '(is 1 1 2)', "nil\n", 'is');
language_output_is('Arc', '(is "a b c" "a b c")', "t\n", 'is');
language_output_is('Arc', "(is 'a 'a)", "t\n", 'is');
language_output_is('Arc', "(is 'a 'b)", "nil\n", 'is');
language_output_is('Arc', "(is "a" 'a)", "nil\n", 'is');
language_output_is('Arc', '(is #\a "a")', "nil\n", 'is');
language_output_is('Arc', '(is 1 1 1 1)', "t\n", 'is');
language_output_is('Arc', '(is 1 1 1 2)', "nil\n", 'is');

## iso
language_output_is('Arc', '(iso)', "t\n", 'empty iso');
language_output_is('Arc', '(iso nil)', "t\n", 'one arg iso');
language_output_is('Arc', '(iso nil nil)', "t\n", 'iso');
language_output_is('Arc', '(iso nil t)', "nil\n", 'iso');
language_output_is('Arc', '(iso 1 nil)', "nil\n", 'iso');
language_output_is('Arc', '(iso 1 t)', "nil\n", 'iso');
language_output_is('Arc', '(iso 1 1)', "t\n", 'iso');
language_output_is('Arc', '(iso 1 1.0)', "t\n", 'iso');
language_output_is('Arc', '(iso 1 1.1)', "nil\n", 'iso');
language_output_is('Arc', '(iso 2 1 2)', "nil\n", 'iso');
language_output_is('Arc', '(iso 1 1 2)', "nil\n", 'iso');
language_output_is('Arc', '(iso "a b c" "a b c")', "t\n", 'iso');
language_output_is('Arc', "(iso 'a 'a)", "t\n", 'iso');
language_output_is('Arc', "(iso 'a 'b)", "nil\n", 'iso');
language_output_is('Arc', "(iso "a" 'a)", "nil\n", 'iso');
language_output_is('Arc', '(iso #\a "a")', "nil\n", 'iso');
language_output_is('Arc', '(iso 1 1 1 1)', "t\n", 'iso');
language_output_is('Arc', '(iso 1 1 1 2)', "nil\n", 'iso');
language_output_is('Arc', "(iso '(1 2 (4 5) 6) '(1 2 (4 5) 6)", "t\n", 'iso');
language_output_is('Arc', "(iso '(1 2 (4 5)) '(1 2 (4 5) 6)", "nil\n", 'iso');
language_output_is('Arc', "(iso '(1 2 (4 5 6) 6) '(1 2 (4 5) 6)", "nil\n", 'iso');


## <
language_output_is('Arc', '(<)', "t\n", '<');
language_output_is('Arc', '(< 1)', "t\n", '<');
language_output_is('Arc', '(< 1 1)', "nil\n", '<');
language_output_is('Arc', '(< 1 2)', "t\n", '<');
language_output_is('Arc', '(< 1 2 3)', "t\n", '<');
language_output_is('Arc', '(< 1 3 2)', "nil\n", '<');
language_output_is('Arc', '(< 1 2 3 4)', "t\n", '<');
language_output_is('Arc', '(< 1 2 3 3)', "nil\n", '<');
language_output_is('Arc', '(< 1 2 3.1 4)', "t\n", '<');
language_output_is('Arc', '(< "abc" "bk" "cl" "cla")', "t\n", '<');
language_output_is('Arc', '(< "abc" "bk" "al" "cla")', "nil\n", '<');

## >
language_output_is('Arc', '(>)', "t\n", '>');
language_output_is('Arc', '(> 1)', "t\n", '>');
language_output_is('Arc', '(> 1 1)', "nil\n", '>');
language_output_is('Arc', '(> 2 1)', "t\n", '>');
language_output_is('Arc', '(> 3 2 1)', "t\n", '>');
language_output_is('Arc', '(> 1 3 2)', "nil\n", '>');
language_output_is('Arc', '(> 4 3 2 1)', "t\n", '>');
language_output_is('Arc', '(> 5 4 3 3)', "nil\n", '>');
language_output_is('Arc', '(> 5 4 3.1 2)', "t\n", '>');
language_output_is('Arc', '(> "abc" "bk" "cl" "cla")', "nil\n", '>');
language_output_is('Arc', '(> "abc" "bk" "al" "cla")', "nil\n", '>');
