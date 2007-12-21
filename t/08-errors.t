#!/usr/bin/perl -w

use strict;
use Test::More tests => 6;

use Text::MicroMason;
my $m = Text::MicroMason->new( );

######################################################################

{
    my $scr_mobj = "Hello <% die('Foo!') %>!";
    
    ok(!eval { $m->execute( text => $scr_mobj ); 1 } );
    like ($@, qr/Foo!/, "Error $@ must match Foo!");

    ok(!eval { $m->execute( text => $scr_mobj ); 1 } );
    like ($@, qr<\QMicroMason execution failed: Foo! at text template (compiled at t/08-errors.t line>, 
          "Error $@ must match MicroMason failure");
  
    ok(! eval { $m->execute( file => 'samples/die.msn' ); 1 } );
    like ($@, qr(\QMicroMason execution failed: Foo! at samples/die.msn line),
          "Error $@ must match MicroMason failure");
}

######################################################################
