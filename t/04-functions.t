#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use lib qw( . lib ../lib ../../lib );

use Test::More tests => 25;
use Parrot::Test;

language_output_is('Arc', '(fn ())', "#<function>\n", "simple fn");
language_output_is('Arc', '(type (fn ()))', "function\n", "type fn");
language_output_is('Arc', '((fn (x) x) 9)', "9\n", "id fn");
language_output_is('Arc', '((fn (x y) y) 1 2)', "2\n", "2 args fn");
language_output_is('Arc', '((fn r r) 1 2 3)', "(1 2 3)\n", "rest arg fn");
language_output_is('Arc', '((fn (x . r) x) 0 1 2)', "0\n", "arg + rest fn");
language_output_is('Arc', '((fn (x . r) r) 0 1 2)', "(1 2)\n", "arg + rest fn");
language_output_is('Arc', '((fn (f x y) (+ (f x) y)) (fn (x) (+ x 1)) 1 2)', "4\n", "fn that takes a fn");
language_output_is('Arc', '(assign f (fn (x) (fn () (assign x (+ x 1))))) (assign g (f 1)) (assign h (f 1)) (g) (h) (h)', "3\n", "simple closure");

language_output_is('Arc', << 'CODE', << 'RES', 'lex scope');
((fn (x) ((fn (x z) z) 4 x)) 1)
CODE
1
RES

language_output_is('Arc', << 'CODE', << 'RES', 'slow fib');
(assign fib 
  (fn (x) 
    (if (< x 2)
      1 
      (+ (fib (- x 1)) (fib (- x 2))))))
(fib 6)
CODE
13
RES

language_output_is('Arc', << 'CODE', << 'RES', 'mutual recursion');
(assign f
  (fn (n) 
    (if (is n 0)
      1 
      (g (- n 1)))))
(assign g
  (fn (n)
    (if (is n 0)
      2 
      (f (- n 1)))))
(f 51)
CODE
2
RES

language_output_is('Arc', << 'CODE', << 'RES', 'closure');
(assign count 
  (fn (n)
    (fn (x)
      (assign n (+ n x)))))
(assign f (count 1))
(assign g (count 1))
(f 78)
(g 6)
(f 100)
(g 2)
CODE
9
RES

## optional arguments
language_output_is('Arc', '((fn (x (o y 1)) (+ x y)) 4)', "5\n", "opt arg");
language_output_is('Arc', '((fn (x (o y 1)) (+ x y)) 4 5)', "9\n", "opt arg");
language_output_is('Arc', '((fn (x (o y)) (cons x y)) 4)', "(4)\n", "opt arg");
language_output_is('Arc', '((fn (x (o y)) (cons x y)) 4 5)', "(4 . 5)\n", "opt arg");
language_output_is('Arc', '((fn ((o x 1) (o y 2)) (+ x y)))', "3\n", "opt arg");
language_output_is('Arc', '(assign o 9) ((fn ((y . u) (o x 1)) (cons y o)) \'(1 . 2))', "(1 . 9)\n", "'o isn't an arg list name");

## destructuring
language_output_is('Arc', "((fn ((x y) z) (list x y z)) '(1 2) 4)", "(1 2 4)\n", "destructuring");
language_output_is('Arc', "((fn ((x . y) z) (list x y z)) '(1 2 3) 4)", "(1 (2 3) 4)\n", "destructuring");
language_output_is('Arc', "((fn (z (x (y . w)) . r) (list z x y w r)) 0 '(1 (2 (3 . 4))) 5 6 7)", "(0 1 2 ((3 . 4)) (5 6 7))\n", "destructuring");

## apply
language_output_is('Arc', "(apply (fn (x y . r) (list x y r)) '(1 2 (3 4) 5 6))", "(1 2 ((3 4) 5 6))\n", 'apply');
language_output_is('Arc', "(apply (fn (x y) (list x y)) 1 '(2))", "(1 2)\n", 'apply');
language_output_is('Arc', "(apply (fn (x y . r) (list x y r)) 1 2 3 '(4 5))", "(1 2 (3 4 5))\n", 'apply');
