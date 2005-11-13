#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 12 }

my $loaded;
END { ok(0) unless $loaded; }

use Text::MicroMason;

my $m = Text::MicroMason::Base->new( -Sprintf );

ok( $loaded = 1 );

######################################################################

{

  my $scr_hello = 'Hello %s!';
  
  my $res_hello = 'Hello World!';

  ok( $m->execute( text => $scr_hello, 'World'), $res_hello );
  
  ok( $m->compile( text => $scr_hello)->('World'), $res_hello );
  
  my $scriptlet;
  ok( ( $scriptlet = $m->compile( text => $scr_hello) ) and 1 );
  ok( $scriptlet->('World'), $res_hello );
  ok( $scriptlet->('World'), $res_hello );

}

######################################################################

{

  my $scr_hello = <<'ENDSCRIPT';
Hello %s!
How are ya?
ENDSCRIPT
  
  my $res_hello = <<'ENDSCRIPT';
Hello World!
How are ya?
ENDSCRIPT
  
  ok( $m->execute( text => $scr_hello, 'World'), $res_hello );
  
  ok( $m->compile( text => $scr_hello)->('World'), $res_hello );
  
  my $scriptlet;
  ok( ( $scriptlet = $m->compile( text => $scr_hello) ) and 1 );
  ok( $scriptlet->('World'), $res_hello );
  ok( $scriptlet->('World'), $res_hello );

}

######################################################################

{
  my $m = Text::MicroMason::Base->new( -Sprintf );

  my $res_hello = "Hello World!\n";

  ok( $m->execute( handle => \*DATA, 'World'), $res_hello );
}

######################################################################

__DATA__
Hello %s!
