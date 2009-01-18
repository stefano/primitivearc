#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use lib qw( . lib ../lib ../../parrot/lib ../parrot/lib );

use Test::More tests => 16;
use Parrot::Test;

language_output_is('Arc', '(+)', "0\n", '(+)');
language_output_is('Arc', '(+ 1)', "1\n", '(+ 1)');
language_output_is('Arc', '(+ 0 1)', "1\n", '(+ 0 1)');
language_output_is('Arc', '(+ 1 2)', "3\n", '2 int add');
language_output_is('Arc', '(+ 1 2 4)', "7\n", '3 int add');
language_output_is('Arc', '(+ 1.1 2.2)', "3.3\n", '2 float add');
language_output_is('Arc', '(+ 1.1 2.2 4.4)', "7.7\n", '3 float add');
language_output_is('Arc', '(+ 1 4.4 2)', "7.4\n", 'int&float add');

language_output_is('Arc', '(-)', "0\n", '(-)');
language_output_is('Arc', '(- 1)', "-1\n", '(- 1)');
language_output_is('Arc', '(- 1 0)', "1\n", '(- 1 0)');
language_output_is('Arc', '(- 1 2)', "-1\n", '2 int sub');
language_output_is('Arc', '(- 1 2 4)', "-5\n", '3 int sub');
language_output_is('Arc', '(- 1.1 2.2)', "-1.1\n", '2 float sub');
language_output_is('Arc', '(- 1.1 2.2 4.4)', "-5.5\n", '3 float sub');
language_output_is('Arc', '(- 1 4.4 2)', "-5.4\n", 'int&float sub');
