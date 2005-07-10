#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 2 }

use Text::MicroMason;
my $m = Text::MicroMason->new( -Debug, debug => { default => 0 } );

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
 
  my $scriptlet;
  ok( ( $scriptlet = $m->compile( text => $scr_hello) ) and 1 );
  ok( $scriptlet->(), $res_hello );
}

######################################################################
