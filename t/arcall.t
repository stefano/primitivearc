#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use lib qw( . lib ../lib ../../lib );

use Test::More tests => 5;
use Parrot::Test;

language_output_is('Arc', '("abc" 2)', "#\\c\n", 'arcall on string');
language_output_is('Arc', '("abc" 0)', "#\\a\n", 'arcall on string');
language_output_is('Arc', "('(1 2 3) 1)", "2\n", 'arcall on list');
language_output_is('Arc', "('(1 . 2) 0)", "1\n", 'arcall on cons');
language_output_is('Arc', "(set tb (table)) (sref tb 1 2) (cons (tb 1) (tb 2))", "(nil . 1)\n", 'arcall on table');
