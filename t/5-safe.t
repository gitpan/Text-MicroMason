#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 19 }

my $loaded;
END { ok(0) unless $loaded; }

use Text::MicroMason qw( safe_compile safe_execute try_safe_compile try_safe_execute );

ok( $loaded = 1 );

######################################################################

{
  my $scr_bold = '<b><% $ARGS{label} %></b>';
  ok( safe_compile($scr_bold)->(label=>'Foo'), '<b>Foo</b>' );
  ok( safe_execute($scr_bold, label=>'Foo'), '<b>Foo</b>' );
}

######################################################################

{
  my $scr_time = 'The time is <% time() %>';
  ok( ! try_safe_compile( $scr_time ) );
  ok( ! try_safe_execute( $scr_time ) );
}

######################################################################

{
  my $scr_time = 'The time is <% time() %>';
  my $safe = Safe->new();
  $safe->permit('time');
  ok( try_safe_compile( $safe, $scr_time ) );
  ok( try_safe_execute( $safe, $scr_time ) );
  ok( safe_compile( $safe, $scr_time )->() );
  ok( safe_execute( $safe, $scr_time ) );
}

######################################################################

{
  local $^W;
  my $variable = 'secret';
  my $scr_hidden = '<% $variable %>';
  ok( ! try_safe_execute( $scr_hidden ) !~ /secret/ );
}

{
  local $^W;
  $main::variable = $main::variable = 'secret';
  my $scr_hidden = '<% $main::variable %>';
  ok( try_safe_execute( $scr_hidden ) !~ /secret/ );
}

{
  local $^W;
  $Foo::variable = $Foo::variable = 'secret';
  my $scr_hidden = '<% $Foo::variable %>';
  ok( try_safe_execute( $scr_hidden ) !~ /secret/ );
}

######################################################################

{
  my $scr_mobj = 'You\'ve been compiled by <% ref $m %>.';
  
  ok( safe_execute( $scr_mobj ) =~ /Text::MicroMason::SafeFacade/ );
}

######################################################################

{
  my $script = qq| <& 't/test.msn', %ARGS &> |;
  
  my ($output, $err) = try_safe_execute($script, name => 'Sam', hour => 9);
  ok( ! defined $output );
  ok( $err =~ /Can't call .*?execute/ );
}

my $safe_mason = Text::MicroMason->class( 'Safe' );
{
  my $script = qq| <& 't/test.msn', %ARGS &> |;
  my $m = $safe_mason->new();
  
  my $output = eval{ $m->execute( text => $script, name => 'Sam', hour => 9)};
  ok( ! defined $output );
  ok( $@ =~ /Can't call .*?execute/ );
}

{
  my $script = qq| <& 't/test.msn', %ARGS &> |;
  my $m = $safe_mason->new( safe_methods => 'execute' );
  
  my $output = eval{ $m->execute( text => $script, name => 'Sam', hour => 9)};
  ok( length $output );
  ok( ! $@ );
}

######################################################################
