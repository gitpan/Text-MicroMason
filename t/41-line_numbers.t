#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 21 }

use Text::MicroMason;

######################################################################

{
  my $m = Text::MicroMason->new( -LineNumbers );
  my $output = eval { $m->execute( text=>'Hello <% $_[0] %>!', 'world' ) };
  ok( ! $@ );
  ok( $output, 'Hello world!' );
}

######################################################################

{
  my $m = Text::MicroMason->new( -LineNumbers );
  my $output = eval { $m->interpret( text=>'1' ) };
  ok( ! $@ );
  ok( $output =~ m{# line 0 "text template [(]compiled at \S+line_numbers.t line \d+[)]"}s );
}

######################################################################

{
  my $m = Text::MicroMason->new( -LineNumbers );
  my $output = eval { $m->execute( text=>'Hello <% $__[] %>!', 'world' ) };
  ok( ! $output );
  ok( $@ =~ m{requires explicit package name at text template [(]compiled at \S+.t line \d+[)] line (\d+)} );
  ok( $1, 1 );
}

{
  my $m = Text::MicroMason->new( -LineNumbers );

  my $output = eval { $m->execute( text=> "\n\n" . 'Hello <% $__[] %>!', 'world' ) };
  ok( ! $output );
  ok( $@ =~ m{requires explicit package name at text template [(]compiled at \S+.t line \d+[)] line (\d+)} );
  ok( $1, 3 );
}

######################################################################

{
  my $m = Text::MicroMason->new( -LineNumbers );
  my $output = eval { $m->execute( inline=>'Hello <% $_[0] %>!', 'world' ) };
  ok( ! $@ );
  ok( $output, 'Hello world!' );
}

{
  my $m = Text::MicroMason->new( -LineNumbers );
  my $output = eval { $m->interpret( inline=>'1' ) };
  ok( ! $@ );
  ok( $output =~ m{# line \d+ "\S+line_numbers.t"}s );
}

{
  my $m = Text::MicroMason->new( -LineNumbers );
  my $output = eval { $m->execute( inline=>'Hello <% $__[] %>!', 'world' ) }; my $line = __LINE__;
  ok( ! $output );
  ok( $@ =~ m{requires explicit package name at \S+.t line (\d+)} );
  ok( $1 == $line);
}

######################################################################

{
  my $m = Text::MicroMason->new( -LineNumbers );
  my $output = eval { $m->execute( file=>'samples/test.msn', name=>'Sam', hour=>14 ) };
  ok( ! $@ );
  ok( $output =~ /\QGood afternoon, Sam!\E/ );
}

{
  my $m = Text::MicroMason->new( -LineNumbers );
  my $output = eval { $m->execute( file=>'samples/die.msn' ) };
  ok( ! $output );
  ok( $@, "MicroMason execution failed: Foo! at samples/die.msn line 1.\n" );
}

######################################################################
