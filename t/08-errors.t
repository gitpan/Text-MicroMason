#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 4 }

use Text::MicroMason;
my $m = Text::MicroMason->new( );

######################################################################

{
  my $scr_mobj = "Hello <% die('Foo!') %>!";
  
  ok( ! eval { $m->execute( text => $scr_mobj ); 1 } );
  
  ok( do { eval { $m->execute( text => $scr_mobj ) }; $@ } =~ 'Foo!' );
  
  ok( do { eval { $m->execute( text => $scr_mobj ) }; $@ }
	    =~ "\QMicroMason execution failed: Foo! at text template (compiled at t/08-errors.t line" );
  
  ok( do { eval { $m->execute( file => 'samples/die.msn' ) }; $@ } 
	    =~ "\QMicroMason execution failed: Foo! at samples/die.msn line" );
}

######################################################################
