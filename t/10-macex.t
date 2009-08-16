#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use lib qw( . lib ../lib ../../lib );

use Test::More tests => 4;
use Parrot::Test;

language_output_is('Arc', << 'CODE', << 'RES', 'mac');
(assign r2
  (annotate 'mac
    (fn (x y)
      (list y x))))
(r2 42 list)
CODE
(42)
RES

language_output_is('Arc', << 'CODE', << 'RES', 'mac');
(assign m1
  (annotate 'mac
    (fn (x)
      (list 'm2 x))))
(assign m2
  (annotate 'mac
    (fn (n)
      (list '+ n 1))))
(m1 90)
CODE
91
RES

language_output_is('Arc', << 'CODE', << 'RES', 'macex1');
(assign m1
  (annotate 'mac
    (fn (x)
      (list 'm2 x))))
(assign m2
  (annotate 'mac
    (fn (n)
      (list '+ n 1))))
(macex1 '(m1 90))
CODE
(m2 90)
RES

language_output_is('Arc', << 'CODE', << 'RES', 'macex');
(assign m1
  (annotate 'mac
    (fn (x)
      (list 'm2 x))))
(assign m2
  (annotate 'mac
    (fn (n)
      (list '+ n 1))))
(macex '(m1 90))
CODE
(+ 90 1)
RES
