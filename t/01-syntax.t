#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 6 }

use Text::MicroMason;
my $m = Text::MicroMason->new();

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
  
  ok( $m->execute( text => $scr_hello), $res_hello );
  
  ok( $m->compile( text => $scr_hello)->(), $res_hello );
  
  my $scriptlet;
  ok( ( $scriptlet = $m->compile( text => $scr_hello) ) and 1 );
  ok( $scriptlet->(), $res_hello );
  ok( $scriptlet->(), $res_hello );
  ok( $scriptlet->(), $res_hello );
}

######################################################################
