#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use lib qw( . lib ../lib ../../lib );

use Test::More tests => 21;
use Parrot::Test;

language_output_is('Arc', "'1", "1\n", 'quote');
language_output_is('Arc', "'#\\a", "#\\a\n", 'quote');
language_output_is('Arc', "'\"a b\"", "\"a b\"\n", 'quote');
language_output_is('Arc', "'(1 2 (3 . 4) 5)", "(1 2 (3 . 4) 5)\n", 'quote');
language_output_is('Arc', "'symbol-symbol", "symbol-symbol\n", 'quote');

language_output_is('Arc', "`1", "1\n", 'simple quasiquote');
language_output_is('Arc', "`#\\a", "#\\a\n", 'simple quasiquote');
language_output_is('Arc', "`\"a b\"", "\"a b\"\n", 'simple quasiquote');
language_output_is('Arc', "`(1 2 (3 . 4) 5)", "(1 2 (3 . 4) 5)\n", 'simple quasiquote');
language_output_is('Arc', "`symbol-symbol", "symbol-symbol\n", 'simple quasiquote');

language_output_is('Arc', "(assign x 9) `,x", "9\n", 'quasiquote with unquote');
language_output_is('Arc', "(assign x 9) `(1 . ,x)", "(1 . 9)\n", 'quasiquote with unquote');
language_output_is('Arc', "(assign x 9) `(,x y 3)", "(9 y 3)\n", 'quasiquote with unquote');
language_output_is('Arc', "(assign x 9) `(3 (1 (,x 0)) v)", "(3 (1 (9 0)) v)\n", 'quasiquote with unquote');
language_output_is('Arc', "(assign x 9) ``,,x", "9\n", 'nested quasiquote with unquote');
language_output_is('Arc', "(assign x 9) `(1 `(2 ,,x 3) m)", "(1 (2 9 3) m)\n", 'nested quasiquote with unquote');

language_output_is('Arc', '(assign x (list 1 2)) `(,@x)', "(1 2)\n", 'quasiquote with splice');
language_output_is('Arc', '(assign x (list 1 2)) `(0 ,@x 3)', "(0 1 2 3)\n", 'quasiquote with splice');
language_output_is('Arc', '(assign x (list 1 2)) `(k (,@x . z) h)', "(k (1 2 . z) h)\n", 'quasiquote with splice');
language_output_is('Arc', '(assign x (list 1 2)) `(l (k (g ,@x) 3))', "(l (k (g 1 2) 3))\n", 'quasiquote with splice');
language_output_is('Arc', '(assign x (list 1 2)) `(1 `(k ,,@x v) ,@x w)', "(1 (k 2 3 v) 1 2 w)\n", 'nested quasiquote with splice');
