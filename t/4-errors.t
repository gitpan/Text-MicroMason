#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 12 }

my $loaded;
END { ok(0) unless $loaded; }

use Text::MicroMason qw( compile execute try_compile try_execute );

ok( $loaded = 1 );

######################################################################

my $scr_syn = '<b><% if ( 1 ) %></b>';
my $res_syn = eval { compile($scr_syn) };
ok( ! $res_syn );
ok( $@ =~ /MicroMason compilation failed/ );
ok( $@ =~ /syntax error/ );
ok( ! defined try_compile($scr_syn) );
ok( ! defined try_execute($scr_syn) );

my $scr_die = '<b><% die "FooBar" %></b>';
ok( compile($scr_die) and 1 );
my $res_die = eval { execute($scr_die) };
ok( ! $res_die );
ok( $@ =~ /MicroMason execution failed/ );
ok( $@ =~ /FooBar/ );
ok( ref try_compile($scr_die) eq 'CODE' );
ok( ! defined try_execute($scr_die) );
