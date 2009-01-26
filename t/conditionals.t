#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use lib qw( . lib ../lib ../../lib );

use Test::More tests => 10;
use Parrot::Test;

language_output_is('Arc', '(if)', "nil\n", "if");
language_output_is('Arc', '(if 1)', "1\n", "if");
language_output_is('Arc', '(if nil)', "nil\n", "if");
language_output_is('Arc', '(if t)', "t\n", "if");
language_output_is('Arc', '(if 1 2)', "2\n", "if");
language_output_is('Arc', '(if t 1 2)', "1\n", "if");
language_output_is('Arc', '(if nil 1 2)', "2\n", "if");
language_output_is('Arc', '(if nil 1 (if t 2 3))', "2\n", "if");
language_output_is('Arc', '(if nil 1 (if t nil t) 2 t 3)', "3\n", "if");
language_output_is('Arc', '(if nil 1 (if t nil t) 2 3)', "3\n", "if");
