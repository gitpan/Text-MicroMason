#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 8 }

use Text::MicroMason;

######################################################################

{ 
  my $m = Text::MicroMason->new();

  use vars qw( $sub_fib $count_fib );
  $count_fib = 0;
  my $scr_fib = q{<% my $x = shift; ++ $::count_fib; $x < 3 ? 1 : &$::sub_fib( $x - 1 ) + &$::sub_fib( $x - 2 ) %>};
  $sub_fib = $m->compile( text => $scr_fib );
  
  ok( &$sub_fib( 10 ), 55 ); 	# Fibonaci calculation works
  ok( $count_fib, 109 );	# Without caching we need to do this a lot
}

######################################################################

{ 
  my $m = Text::MicroMason->new( -ExecuteCache );

  use vars qw( $sub_fib $count_fib );
  $count_fib = 0;
  my $scr_fib = q{<% my $x = shift; ++ $::count_fib; $x < 3 ? 1 : &$::sub_fib( $x - 1 ) + &$::sub_fib( $x - 2 ) %>};
  $sub_fib = $m->compile( text => $scr_fib );
  
  ok( &$sub_fib( 10 ), 55 ); 	# Fibonaci calculation works
  ok( $count_fib, 10 );		# With caching we only do this a few times
}


######################################################################

{ 
  require Text::MicroMason::Cache::Null;
  my $m = Text::MicroMason->new( -ExecuteCache, 
		execute_cache => Text::MicroMason::Cache::Null->new );

  use vars qw( $sub_fib $count_fib );
  $count_fib = 0;
  my $scr_fib = q{<% my $x = shift; ++ $::count_fib; $x < 3 ? 1 : &$::sub_fib( $x - 1 ) + &$::sub_fib( $x - 2 ) %>};
  $sub_fib = $m->compile( text => $scr_fib );
  
  ok( &$sub_fib( 10 ), 55 ); 	# Fibonaci calculation works
  ok( $count_fib, 109 );	# Without caching we need to do this a lot
}


######################################################################

{ 
  my $m = Text::MicroMason->new( -ExecuteCache, -CompileCache );

  use vars qw( $sub_fib $count_fib );
  $count_fib = 0;
  my $scr_fib = q{<% my $x = shift; ++ $::count_fib; $x < 3 ? 1 : &$::sub_fib( $x - 1 ) + &$::sub_fib( $x - 2 ) %>};
  $sub_fib = sub { $m->execute( text => $scr_fib, @_ ) };
  
  ok( &$sub_fib( 10 ), 55 ); 	# Fibonaci calculation works
  ok( $count_fib, 10 );		# With caching we only do this a few times
}

######################################################################
