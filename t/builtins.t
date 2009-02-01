#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use lib qw( . lib ../lib ../../lib );

use Test::More tests => 32;
use Parrot::Test;

## tests for builtin functions

language_output_like('Arc', '(err "ho")', 'Error', 'err');
language_output_is('Arc', '(is (uniq) (uniq))', "nil\n", 'uniq');
language_output_is('Arc', '(type (uniq))', "sym\n", 'uniq');
