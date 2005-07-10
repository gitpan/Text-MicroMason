#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 9 }

my $loaded;
END { ok(0) unless $loaded; }

use Text::MicroMason qw( compile execute );

ok( $loaded = 1 );

######################################################################

{
  my $scr_hello = <<'ENDSCRIPT';
% my $noun = 'World';
Hello <% $noun %>!
How are ya?
ENDSCRIPT
  
  my $res_hello = <<'ENDSCRIPT';
Hello World!
How are ya?
ENDSCRIPT
  
  ok( execute($scr_hello), $res_hello );
  
  ok( compile($scr_hello)->(), $res_hello );
  
  my $scriptlet;
  ok( ( $scriptlet = compile($scr_hello) ) and 1 );
  ok( $scriptlet->(), $res_hello );
  ok( $scriptlet->(), $res_hello );
  ok( $scriptlet->(), $res_hello );
}

######################################################################

{
  my $scr_bold = '<b><% $ARGS{label} %></b>';
  ok( execute($scr_bold, label=>'Foo'), '<b>Foo</b>' );
  ok( compile($scr_bold)->(label=>'Foo'), '<b>Foo</b>' );
}

