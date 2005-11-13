#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 17 }

my $loaded;
END { ok(0) unless $loaded; }

use Text::MicroMason;

my $m = Text::MicroMason::Base->new( -DoubleQuote );

ok( $loaded = 1 );

######################################################################

{

  my $scr_hello = 'Hello $ARGS{noun}!';
  
  my $res_hello = 'Hello World!';

  ok( $m->execute( text => $scr_hello, noun => 'World'), $res_hello );
  
  ok( $m->compile( text => $scr_hello)->(noun => 'World'), $res_hello );
  
  my $scriptlet;
  ok( ( $scriptlet = $m->compile( text => $scr_hello) ) and 1 );
  ok( $scriptlet->(noun => 'World'), $res_hello );
  ok( $scriptlet->(noun => 'World'), $res_hello );

}

######################################################################

{

  my $scr_hello = <<'ENDSCRIPT';
${ $::noun = 'World'; \( "" ) }Hello $::noun!
How are ya?
ENDSCRIPT
  
  my $res_hello = <<'ENDSCRIPT';
Hello World!
How are ya?
ENDSCRIPT
  
  ok( $m->execute( text => $scr_hello, noun => 'World'), $res_hello );
  
  ok( $m->compile( text => $scr_hello)->(noun => 'World'), $res_hello );
  
  my $scriptlet;
  ok( ( $scriptlet = $m->compile( text => $scr_hello) ) and 1 );
  ok( $scriptlet->(noun => 'World'), $res_hello );
  ok( $scriptlet->(noun => 'World'), $res_hello );

}

######################################################################

{

  my $m = Text::MicroMason::Base->new( -DoubleQuote, -PassVariables );

  my $scr_hello = 'Hello $noun!';
  
  my $res_hello = 'Hello World!';

  ok( $m->execute( text => $scr_hello, noun => 'World'), $res_hello );
  
  ok( $m->compile( text => $scr_hello)->(noun => 'World'), $res_hello );
  
  my $scriptlet;
  ok( ( $scriptlet = $m->compile( text => $scr_hello) ) and 1 );
  ok( $scriptlet->(noun => 'World'), $res_hello );
  ok( $scriptlet->(noun => 'World'), $res_hello );

}

######################################################################

{
  my $m = Text::MicroMason::Base->new( -DoubleQuote, -PassVariables );

  my $res_hello = "Hello World!\n";

  ok( $m->execute( handle => \*DATA, noun => 'World'), $res_hello );
}

######################################################################

__DATA__
Hello $noun!
