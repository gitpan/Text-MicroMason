#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 1 }

my $loaded;
END { ok(0) unless $loaded; }

use Text::MicroMason qw( compile execute );

ok( $loaded = 1 );

######################################################################

1;
