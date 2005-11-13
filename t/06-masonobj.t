#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 1 }

use Text::MicroMason;
my $m = Text::MicroMason->new();

######################################################################

{
  my $scr_mobj = 'You\'ve been compiled by <% ref $m %>.';
  
  my $res_mobj = 'You\'ve been compiled by Text::MicroMason';
  
  ok( $m->execute( text => $scr_mobj) =~ /^\Q$res_mobj\E/ );
}

######################################################################

