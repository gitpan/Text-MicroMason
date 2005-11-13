#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 20 }

use Text::MicroMason;
my $m = Text::MicroMason->new();

######################################################################

{
  my $scr_hello = "Hello <% shift(@_) %>!";
  
  my $res_hello = "Hello World!";
  
  ok( $m->execute( text => $scr_hello, 'World' ), $res_hello );
  
  ok( $m->compile( text => $scr_hello)->( 'World' ), $res_hello );
}

######################################################################

{
my $scr_bold = '<b><% $ARGS{label} %></b>';
ok( $m->execute( text => $scr_bold, label=>'Foo'), '<b>Foo</b>' );
ok( $m->compile( text => $scr_bold)->(label=>'Foo'), '<b>Foo</b>' );
}

######################################################################

SIMPLE_ARGS: {
  my $scr_bold = '<%args>$label</%args><b><% $label %></b>';
  ok( $m->execute( text => $scr_bold, label=>'Foo'), '<b>Foo</b>' );
  ok( $m->compile( text => $scr_bold)->(label=>'Foo'), '<b>Foo</b>' );
  ok( ! eval { $m->execute( text => $scr_bold); 1 } );
}

######################################################################

ARGS_BLOCK_WITH_DEFAULT: {
  my $scr_hello = <<'ENDSCRIPT';
<%args>
  $name
  $hour => (localtime)[2]
</%args>
% if ( $name eq 'Dave' ) {
  I'm sorry <% $name %>, I'm afraid I can't do that right now.
% } else {
  <%perl>
    my $greeting = ( $hour > 11 ) ? 'afternoon' : 'morning'; 
  </%perl>
  Good <% $greeting %>, <% $name %>!
% }
ENDSCRIPT

  my $res_hello = <<'ENDSCRIPT';
    Good afternoon, World!
ENDSCRIPT

  ok( $m->execute( text => $scr_hello, name => 'World', hour => 13), $res_hello );
  ok( $m->compile( text => $scr_hello)->(name => 'World', hour => 13), $res_hello );
  ok( eval { $m->execute( text => $scr_hello, name => 'World'); 1 } );
  ok( ! eval { $m->execute( text => $scr_hello, hour => 13); 1 } );
  ok( ! eval { $m->execute( text => $scr_hello); 1 } );
}

######################################################################

ARGS_BLOCK_WITH_DEFAULT_LIST: {
  my $scr_count = <<'ENDSCRIPT';
<%args>
 @data => ()
</%args>
Count: <% scalar @data %>
ENDSCRIPT

  my $res_count_0 = "Count: 0\n";
  my $res_count_1 = "Count: 1\n";
  my $res_count_2 = "Count: 2\n";

  ok( $m->execute( text => $scr_count ), $res_count_0 );
  ok( $m->execute( text => $scr_count, data => [] ), $res_count_0 );
  ok( $m->execute( text => $scr_count, data => [ 1 ] ), $res_count_1 );
  ok( $m->execute( text => $scr_count, data => [ 1 .. 2 ] ), $res_count_2 );
}

######################################################################

ARGS_BLOCK_WITH_DEFAULT_LIST: {
  my $scr_count = <<'ENDSCRIPT';
<%args>
 @data => ( 1 )
</%args>
Count: <% scalar @data %>
ENDSCRIPT

  my $res_count_0 = "Count: 0\n";
  my $res_count_1 = "Count: 1\n";
  my $res_count_2 = "Count: 2\n";

  ok( $m->execute( text => $scr_count ), $res_count_1 );
  ok( $m->execute( text => $scr_count, data => [] ), $res_count_0 );
  ok( $m->execute( text => $scr_count, data => [ 1 ] ), $res_count_1 );
  ok( $m->execute( text => $scr_count, data => [ 1 .. 2 ] ), $res_count_2 );
}

######################################################################

