#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 4 }

use Text::MicroMason;

######################################################################

{
  my $m = Text::MicroMason->new( -AllowGlobals );
  $m->allow_globals( '$name' );
  my $output = $m->execute( text=>'Hello <% $name || "" %>!' );
  ok( $output, 'Hello !' );
}

######################################################################

{
  my $m = Text::MicroMason->new( -AllowGlobals );
  $m->allow_globals( '$name' );
  $m->set_globals( '$name' => 'Bob' );
  my $output = $m->execute( text=>'Hello <% $name %>!' );
  ok( $output, 'Hello Bob!' );
}

######################################################################

{
  my $m = Text::MicroMason->new( -AllowGlobals );
  $m->allow_globals( '$count' );
  my $sub = $m->compile( text=>'Item <% ++ $count %>.' );
  my $output = $sub->();
  ok( $output, 'Item 1.' );
  $output = $sub->();
  ok( $output, 'Item 2.' );
}

######################################################################
