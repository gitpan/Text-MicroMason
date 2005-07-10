#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 32 }

use Text::MicroMason;
my $m = Text::MicroMason->new();

######################################################################

{
  my $scr_hello = <<'ENDSCRIPT';
% my $noun = 'World';
Hello <% $noun %>!
How are ya?
ENDSCRIPT
  
  my $res_hello = <<'ENDSCRIPT';
Hello World!
How are ya?
ENDSCRIPT
  
  ok( $m->execute( text => $scr_hello), $res_hello );
  
  ok( $m->compile( text => $scr_hello)->(), $res_hello );
  
  my $scriptlet;
  ok( ( $scriptlet = $m->compile( text => $scr_hello) ) and 1 );
  ok( $scriptlet->(), $res_hello );
  ok( $scriptlet->(), $res_hello );
  ok( $scriptlet->(), $res_hello );
}

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

FLOW_CONTROL: {

  my $scr_rand = <<'ENDSCRIPT';
% if ( int rand 2 ) {
  Hello World!
% } else {
  Goodbye Cruel World!
% }
ENDSCRIPT
  
  my $scriptlet = $m->compile( text => $scr_rand);
  
  my %results;
  for ( 0 .. 99 ) {
    $results{ &$scriptlet } ++;
  }

  ok( scalar keys %results, 2 );

}

######################################################################

PERL_BLOCK: {
  
  my $scr_count = <<'ENDSCRIPT';
Counting...
<%perl>
  foreach ( 1 .. 9 ) {
     $_out->( $_ )
  }
</%perl>
Done!
ENDSCRIPT

  my $res_count = <<'ENDSCRIPT';
Counting...
123456789Done!
ENDSCRIPT
  
  ok( $m->execute( text => $scr_count), $res_count );

}

SPANNING_PERL: {
  
  my $scr_count = <<'ENDSCRIPT';
<table><tr>
<%perl> foreach ( 1 .. 9 ) { </%perl>
  <td><b><% $_ %></b></td>
<%perl> } </%perl>
</tr></table>
ENDSCRIPT

  my $res_count = <<'ENDSCRIPT';
<table><tr>
  <td><b>1</b></td>
  <td><b>2</b></td>
  <td><b>3</b></td>
  <td><b>4</b></td>
  <td><b>5</b></td>
  <td><b>6</b></td>
  <td><b>7</b></td>
  <td><b>8</b></td>
  <td><b>9</b></td>
</tr></table>
ENDSCRIPT
  
  ok( $m->execute( text => $scr_count), $res_count );

}

######################################################################

SUBTEMPLATE: {
  my $scr_closure = <<'ENDSCRIPT';
% my $draw_item = sub {
%   my $item = shift;
<p><b><% $item %></b><br>
  <a href="/more?item=<% $item %>">Find out more about <% $item %>.</p>
% };
<h1>We've Got Items!</h1>
% foreach my $item ( qw( Foo Bar Baz ) ) {
%   $draw_item->( $item );
% }
ENDSCRIPT
  
  my $res_closure = <<'ENDSCRIPT';
<h1>We've Got Items!</h1>
<p><b>Foo</b><br>
  <a href="/more?item=Foo">Find out more about Foo.</p>
<p><b>Bar</b><br>
  <a href="/more?item=Bar">Find out more about Bar.</p>
<p><b>Baz</b><br>
  <a href="/more?item=Baz">Find out more about Baz.</p>
ENDSCRIPT
  
  ok( $m->execute( text => $scr_closure), $res_closure );
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

SIMPLE_INIT_BLOCK: {
  my $scr_hello = <<'ENDSCRIPT';
I'm sorry <% $name %>, I'm afraid I can't do that right now.
<%init>
  my $name = 'Dave';
</%init>
ENDSCRIPT

  my $res_hello = <<'ENDSCRIPT';
I'm sorry Dave, I'm afraid I can't do that right now.
ENDSCRIPT

  ok( $m->execute( text => $scr_hello), $res_hello );
  ok( $m->compile( text => $scr_hello)->(), $res_hello );
}

######################################################################

SIMPLE_ONCE_BLOCK: {
  my $scr_hello = <<'ENDSCRIPT';
I'm sorry <% $name %>, I'm afraid I can't do that right now.
<%once>
  my $name = 'Dave';
</%once>
ENDSCRIPT

  my $res_hello = <<'ENDSCRIPT';
I'm sorry Dave, I'm afraid I can't do that right now.
ENDSCRIPT

  ok( $m->execute( text => $scr_hello), $res_hello );
  ok( $m->compile( text => $scr_hello)->(), $res_hello );
}

######################################################################

ONCE_AND_INIT_BLOCKS: {
  my $scr_count = <<'ENDSCRIPT';
The count is now <% $count %>.
<%once>
  my $count = 100;
</%once>
<%init>
  $count ++;
</%init>
ENDSCRIPT

  ok( $m->execute( text => $scr_count),     "The count is now 101.\n" );
  ok( $m->compile( text => $scr_count)->(), "The count is now 101.\n" );
  my $sub_count = $m->compile( text => $scr_count);
  ok( $sub_count->(), "The count is now 101.\n" );
  ok( $sub_count->(), "The count is now 102.\n" );
  ok( $sub_count->(), "The count is now 103.\n" );
}

######################################################################

{
  my $scr_mobj = 'You\'ve been compiled by <% ref $m %>.';
  
  my $res_mobj = 'You\'ve been compiled by Text::MicroMason';
  
  ok( $m->execute( text => $scr_mobj) =~ /^\Q$res_mobj\E/ );
}

######################################################################
