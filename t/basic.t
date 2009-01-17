#!/ust/bin/perl

use strict;
use warnings;
use utf8;

use lib qw( . lib ../lib ../../parrot/lib ../parrot/lib );

use Test::More tests => 11;
use Parrot::Test;

language_output_is('Arc', '-1234', "-1234\n", 'neg number');
language_output_is('Arc', '0', "0\n", 'zero number');
language_output_is('Arc', '1234', "1234\n", 'pos number');

language_output_is('Arc', '100000000000000000000000', "100000000000000000000000\n", 'big number');

language_output_is('Arc', '-3.467', "-3.467\n", 'float neg number');
language_output_is('Arc', '3.467', "3.467\n", 'float pos number');
language_output_is('Arc', '-0', "0\n", 'float zero number');

language_output_is('Arc', '#\a', "a\n", 'simple char');
language_output_is('Arc', '#\space', " \n", 'space char');
language_output_is('Arc', '#\newline', "\n\n", 'newline char');
language_output_is('Arc', '#\u263A', "\x{263A}\n", 'unicode char');
