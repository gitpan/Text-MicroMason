#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 12 }

my $loaded;
END { ok(0) unless $loaded; }

use Text::MicroMason;

my $m = Text::MicroMason->new( -ServerPages );

ok( $loaded = 1 );

######################################################################

my $scr_hello = <<'ENDSCRIPT';
<% my $noun = 'World'; %>Hello <%= $noun %>!
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

######################################################################

my $scr_bold = '<b><%= $ARGS{label} %></b>';
ok( $m->execute( text => $scr_bold, label=>'Foo'), '<b>Foo</b>' );
ok( $m->compile( text => $scr_bold)->(label=>'Foo'), '<b>Foo</b>' );

######################################################################

FLOW_CONTROL: {

  my $scr_rand = <<'ENDSCRIPT';
<% if ( int rand 2 ) { %>
  Hello World!
<% } else { %>
  Goodbye Cruel World!
<% } %>
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
<%
  foreach ( 1 .. 9 ) {
     $_out->( $_ )
  }
%>
Done!
ENDSCRIPT

  my $res_count = <<'ENDSCRIPT';
Counting...
123456789
Done!
ENDSCRIPT
  
  ok( $m->execute( text => $scr_count), $res_count );

}

SPANNING_PERL: {
  
  my $scr_count = <<'ENDSCRIPT';
<table><tr>
<% foreach ( 1 .. 9 ) { %>  <td><b><%= $_ %></b></td>
<% } %></tr></table>
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
