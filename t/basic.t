#!/ust/bin/perl

use strict;
use warnings;

use lib qw( . lib ../lib ../../parrot/lib ../parrot/lib );
#use FindBin;
#use lib "$FindBin::Bin/../parrot/lib", "$FindBin::Bin/../../parrot/lib";

use Test::More tests => 3;
use Parrot::Test;

language_output_is('Arc', <<'CODE', <<'OUT', 'number');
-1234
CODE
-1234
OUT

language_output_is('Arc', <<'CODE', <<'OUT', 'number');
0
CODE
0
OUT

language_output_is('Arc', <<'CODE', <<'OUT', 'number');
1234
CODE
1234
OUT
