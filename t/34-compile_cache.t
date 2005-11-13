#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 16 }

use Carp;
$SIG{__DIE__} = \&Carp::confess;

use Text::MicroMason;

######################################################################

{ 
  my $m = Text::MicroMason->new();

  use vars qw( $count_sub $sub_count $local_count );
  $sub_count = 0;
  $local_count = 0;
  my $count_scr = q{<%once> ++ $::sub_count; my $count; </%once><%perl> ++ $::local_count; </%perl><% ++ $count; %>};
  for ( 1 .. 3 ) { 
    $count_sub = $m->compile( text => $count_scr );
    for ( 1 .. 3 ) { 
      &$count_sub($_);
    }
  }

  ok( $sub_count, 3 );
  ok( $local_count, 9 );
  ok( &$count_sub(), 4 );
}

######################################################################

{ 
  my $m = Text::MicroMason->new( -CompileCache );
  foreach ( grep $_, map $m->{$_}, qw( compile_cache_text compile_cache_file execute_cache ) ) { $_->clear() }

  use vars qw( $count_sub $sub_count $local_count );
  $sub_count = 0;
  $local_count = 0;
  my $count_scr = q{<%once> ++ $::sub_count; my $count; </%once><%perl> ++ $::local_count; </%perl><% ++ $count; %>};
  for ( 1 .. 3 ) { 
    $count_sub = $m->compile( text => $count_scr );
    for ( 1 .. 3 ) { 
      &$count_sub($_);
    }
  }

  ok( $sub_count, 1 );
  ok( $local_count, 9 );
  ok( &$count_sub(), 10 );
}

######################################################################

{ 
  my $m = Text::MicroMason->new( -CompileCache, -ExecuteCache );
  foreach ( grep $_, map $m->{$_}, qw( compile_cache_text compile_cache_file execute_cache ) ) { $_->clear() }

  use vars qw( $count_sub $sub_count $local_count );
  $sub_count = 0;
  $local_count = 0;
  my $count_scr = q{<%once> ++ $::sub_count; my $count; </%once><%perl> ++ $::local_count; </%perl><% ++ $count; %>};
  for ( 1 .. 3 ) { 
    $count_sub = $m->compile( text => $count_scr );
    for ( 1 .. 3 ) { 
      &$count_sub($_);
    }
  }

  ok( $sub_count, 1 );
  ok( $local_count, 3 );
  ok( &$count_sub(), 4 );
}

######################################################################

{ 
  my $m = Text::MicroMason->new( -ExecuteCache, -CompileCache );
  foreach ( grep $_, map $m->{$_}, qw( compile_cache_text compile_cache_file execute_cache ) ) { $_->clear() }

  use vars qw( $count_sub $sub_count $local_count );
  $sub_count = 0;
  $local_count = 0;
  my $count_scr = q{<%once> ++ $::sub_count; my $count; </%once><%perl> ++ $::local_count; </%perl><% ++ $count; %>};
  for ( 1 .. 3 ) { 
    $count_sub = $m->compile( text => $count_scr );
    for ( 1 .. 3 ) { 
      &$count_sub($_);
    }
  }

  ok( $sub_count, 1 );
  ok( $local_count, 3 );
  ok( &$count_sub(), 4 );
}

######################################################################

# Test using $m->execute directly: This should compile and run it
# properly.  Running execute 10 times is like running compile once,
# then calling the resulting sub 10 times.

{
  my $m = Text::MicroMason->new( -CompileCache );
  foreach ( grep $_, map $m->{$_}, qw( compile_cache_text compile_cache_file execute_cache ) ) { $_->clear() }

  use vars qw( $count_sub $sub_count $local_count );
  $sub_count = 0;
  $local_count = 0;
  my $count_scr = q{<%once> ++ $::sub_count; my $count; </%once><%perl> ++ $::local_count; </%perl><% ++ $count; %>};
  for ( 1 .. 10 ) {
      $m->execute( text => $count_scr );
  }

  ok( $sub_count, 1 );
  ok( $local_count, 10 );
}

######################################################################

# Test using $m->execute directly, on a file.

{
  my $m = Text::MicroMason->new( -CompileCache );
  foreach ( grep $_, map $m->{$_}, qw( compile_cache_text compile_cache_file execute_cache ) ) { $_->clear() }

  use vars qw( $count_sub $sub_count $local_count );
  $sub_count = 0;
  $local_count = 0;

  for ( 1 .. 10 ) {
      $m->execute( file => "samples/t-counter.msn" );
  }

  ok( $sub_count, 1 );
  ok( $local_count, 10 );

  unlink "t34.txt";
}


######################################################################
