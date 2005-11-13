#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 4 }

use Text::MicroMason;

######################################################################

{
  my $m = Text::MicroMason->new( -PassVariables );
  my $output = $m->execute( text=>'Hello <% $name || "" %>!' );
  ok( $output, 'Hello !' );
}

######################################################################

{
  my $m = Text::MicroMason->new( -PassVariables );
  my $output = $m->execute( text=>'Hello <% $name %>!', 'name' => 'Bob' );
  ok( $output, 'Hello Bob!' );
}

######################################################################

{
  my $m = Text::MicroMason->new( -PassVariables, package => 'foo' );
  $foo::name = $foo::name = 'Bob';
  my $output = $m->execute( text=>'Hello <% $name %>!' );
  ok( $output, 'Hello Bob!' );
}

######################################################################

{
  my $m = Text::MicroMason->new( -PassVariables, package => 'main' );
  local $::name; $::name = 'Bob';
  my $output = $m->execute( text=>'Hello <% $name %>!' );
  ok( $output, 'Hello Bob!' );
}

######################################################################
