#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 9 }

my $loaded;
END { ok(0) unless $loaded; }

use Text::MicroMason qw( safe_compile safe_execute try_safe_compile try_safe_execute );

ok( $loaded = 1 );

######################################################################

my $scr_bold = '<b><% $ARGS{label} %></b>';
ok( safe_compile($scr_bold)->(label=>'Foo'), '<b>Foo</b>' );
ok( safe_execute($scr_bold, label=>'Foo'), '<b>Foo</b>' );
  
my $scr_time = 'The time is <% time() %>';
ok( ! try_safe_compile( $scr_time ) );
ok( ! try_safe_execute( $scr_time ) );

my $safe = Safe->new();
$safe->permit('time');
ok( try_safe_compile( $safe, $scr_time ) );
ok( try_safe_execute( $safe, $scr_time ) );
ok( safe_compile( $safe, $scr_time )->() );
ok( safe_execute( $safe, $scr_time ) );

