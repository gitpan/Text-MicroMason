#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 36 }

my $loaded;
END { ok(0) unless $loaded; }

use Text::MicroMason qw( compile execute );

ok( $loaded = 1 );

######################################################################

BASICS: {
  
  my $scr_hello = <<'ENDSCRIPT';
% my $noun = 'World';
Hello <% $noun %>!
How are ya?
ENDSCRIPT
  
  my $res_hello = <<'ENDSCRIPT';
Hello World!
How are ya?
ENDSCRIPT
  
  ok( execute($scr_hello), $res_hello );
  
  ok( compile($scr_hello)->(), $res_hello );
  
  my $scriptlet;
  ok( ( $scriptlet = compile($scr_hello) ) and 1 );
  ok( $scriptlet->(), $res_hello );
  ok( $scriptlet->(), $res_hello );
  ok( $scriptlet->(), $res_hello );

}

######################################################################

ARG_PASSING: {
  
  my $scr_bold = '<b><% $ARGS{label} %></b>';
  ok( execute($scr_bold, label=>'Foo'), '<b>Foo</b>' );
  ok( compile($scr_bold)->(label=>'Foo'), '<b>Foo</b>' );
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
  
  my $scriptlet = compile($scr_rand);
  
  my %results;
  for ( 0 .. 99 ) {
    $results{ &$scriptlet } ++;
  }

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
123456789
Done!
ENDSCRIPT
  
  ok( execute($scr_count), $res_count );

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
  
  ok( execute($scr_count), $res_count );

}

######################################################################

SUB_TEMPLATES: {
  
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
  
  ok( execute($scr_closure), $res_closure );
}


######################################################################

ERROR_HANDLING: {
  
  my $scr_syn = '<b><% if ( 1 ) %></b>';
  my $res_syn = eval { compile($scr_syn) };
  ok( ! $res_syn );
  ok( $@ =~ /MicroMason compilation failed/ );
  ok( $@ =~ /syntax error/ );
  ok( ! defined Text::MicroMason::try_compile($scr_syn) );
  ok( ! defined Text::MicroMason::try_execute($scr_syn) );

  my $scr_die = '<b><% die "FooBar" %></b>';
  ok( compile($scr_die) and 1 );
  my $res_die = eval { execute($scr_die) };
  ok( ! $res_die );
  ok( $@ =~ /MicroMason execution failed/ );
  ok( $@ =~ /FooBar/ );
  ok( ref Text::MicroMason::try_compile($scr_die) eq 'CODE' );
  ok( ! defined Text::MicroMason::try_execute($scr_die) );

}


######################################################################

use Text::MicroMason qw( safe_compile safe_execute try_safe_compile try_safe_execute );

SAFE: {

  my $scr_bold = '<b><% $ARGS{label} %></b>';
  ok( safe_compile($scr_bold)->(label=>'Foo'), '<b>Foo</b>' );
  ok( safe_execute($scr_bold, label=>'Foo'), '<b>Foo</b>' );
    
  my $scr_time = 'The time is <% time() %>';
  ok( ! try_safe_compile( $scr_time ) );
  ok( ! try_safe_execute( $scr_time ) );
  
  my $safe = Safe->new();
  $safe->permit('time');
  ok( try_safe_compile( $safe, $scr_time ) );
  ok( try_safe_execute( $safe, $scr_time ) );
  ok( safe_compile( $safe, $scr_time )->() );
  ok( safe_execute( $safe, $scr_time ) );
}


######################################################################

use Text::MicroMason qw( try_execute_file try_compile try_execute );

FILE: {
  my $output = try_execute_file('./test.msn', name=>'Sam', hour=>14);
  ok( $output =~ /\QGood afternoon, Sam!\E/ );
}

SYNTAX: {
  my $script = <<'TEXT_END';

<%perl>
  my $hour = $ARGS{hour};
</%perl> xx
% if ( $ARGS{name} eq 'Dave' and $hour > 22 ) {
  I'm sorry <% $ARGS{name} %>, I'm afraid I can't do that right now.
% } else {
  <& './test.msn', name => $ARGS{name}, hour => $hour &>
% }
TEXT_END

  my $code = try_compile($script);
  my $output = try_execute($code, name => 'Sam', hour => 9);
  ok( $output =~ /\QGood morning, Sam!\E/ );
  $output = try_execute($code, name => 'Dave', hour => 23);
  ok( $output =~ /\Qsorry Dave\E/ );
}

FILE_IS_NOT_SAFE: {
  my $script = qq| <& './test.msn', %ARGS &> |;
  
  my ($output, $err) = try_safe_execute($script, name => 'Sam', hour => 9);
  ok( ! defined $output );
  ok( $err =~ /Undefined subroutine/ );
}


