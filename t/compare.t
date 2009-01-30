#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use lib qw( . lib ../lib ../../lib );

use Test::More tests => 18;
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
