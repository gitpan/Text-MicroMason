#!/usr/bin/perl -w

use strict;
use Test::More tests => 6;

use Text::MicroMason;
my $m = Text::MicroMason->new( );

######################################################################

{
    my $scr_mobj = "Hello <% die('Foo!') %>!";

    is eval { $m->execute( text => $scr_mobj ); 1 }, undef;
    like ($@, qr/Foo!/, "Error $@ must match Foo!");

    is eval { $m->execute( text => $scr_mobj ); 1 }, undef;
    like ($@, qr<\QMicroMason execution failed: Foo! at text template (compiled at t/08-errors.t line>, 
          "Error $@ must match MicroMason failure");

    is eval { $m->execute( file => 'samples/die.msn' ); 1 }, undef;
    like ($@, qr(\QMicroMason execution failed: Foo! at samples/die.msn line),
          "Error $@ must match MicroMason failure");
}

######################################################################
