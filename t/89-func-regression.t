#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 24 }

my $loaded;
END { ok(0) unless $loaded; }

use Text::MicroMason qw( compile execute );

ok( $loaded = 1 );

######################################################################

MINIMAL_CASES: {
  ok( execute(''), '' );
  ok( execute(' '), ' ' );
  ok( execute("0"), "0" );
  ok( execute("\n"), "\n" );
}

######################################################################

EMPTY_PERL_LINE: {
  my $scr_re = "x\n%\nx";
  my $res_re = "x\nx";
  ok( execute($scr_re), $res_re );
}

######################################################################

SINGLE_PERL_LINE: {
  my $scr_re = '% $_out->("Potato"); ';
  my $res_re = "Potato";
  ok( execute($scr_re), $res_re );
}

######################################################################

EMPTY_PERL_BLOCK: {
  my $scr_re = '<%perl></%perl>';
  ok( execute($scr_re), '' );
}

######################################################################

SINGLE_PERL_BLOCK: {
  my $scr_re = '<%perl> my $x = time(); </%perl>';
  ok( execute($scr_re), '' );
}

######################################################################

MULTISTATEMENT_EXPR_BLOCK: {
  my $scr_re = '<% my $x = time(); $x %>';
  ok( execute($scr_re), time() );
}

######################################################################

MULTIPLE_PERL_BLOCKS: {
  my $scr_re = '<%perl> my $x = time(); if (0) { </%perl> <%perl> } </%perl>';
  ok( execute($scr_re), '' );
}

######################################################################

SINGLE_PERL_LINE_NEWLINES: {
  my $scr_re = "\n" . '% $_out->("Potato"); ' . "\n\n";
  my $res_re = "\nPotato\n";
  ok( execute($scr_re), $res_re );
}

######################################################################

NEWLINES_AND_PERL_LINES: {
  my $scr_hello = <<'ENDSCRIPT';
% if (1) {
<% "Does this work" %>
% }
correctly?
ENDSCRIPT

  my $res_hello = <<'ENDSCRIPT';
Does this work
correctly?
ENDSCRIPT
  
  ok( execute($scr_hello), $res_hello );
}

######################################################################

NEWLINES_AND_PERL_LINES: {
  my $scr_hello = <<'ENDSCRIPT';

% if ( $ARGS{name} eq 'Dave' ){
  I'm sorry <% $ARGS{name} %>, I'm afraid I can't do that right now.
% } else {
  Good afternoon, <% $ARGS{name} %>!
% }

ENDSCRIPT

  my $res_hello = <<'ENDSCRIPT';

  Good afternoon, Bob!

ENDSCRIPT
  
  ok( execute($scr_hello, name => 'Bob'), $res_hello );
  ok( compile($scr_hello)->( name => 'Bob' ), $res_hello );
}

######################################################################

PERL_BLOCK_AT_EOF: {
  my $scr_hello = 'Hello World<%perl>my $x = time();</%perl>';
  
  my $res_hello = 'Hello World';
  
  ok( execute($scr_hello), $res_hello );
}

######################################################################

ANGLE_PERCENT_BLOCK_AT_EOF: {
  my $scr_hello = '% my $noun = "World";' . "\n" . 'Hello <% $noun %>';
  
  my $res_hello = 'Hello World';
  
  ok( execute($scr_hello), $res_hello );
}

######################################################################

FILE_BLOCK_AT_EOF: {
  my $scr_hello = "<& 'samples/test-recur.msn', name => 'Dave' &>";
  
  my $res_hello = "Test greeting:\n" . 'Good afternoon, Dave!' . "\n";
  
  ok( execute($scr_hello), $res_hello );
}

######################################################################

LOOKS_LIKE_HTML: {
  my $scr_hello = '<TABLE border="1" width="100%"><tr><td>Hi</td></tr></table>';

  ok( execute($scr_hello), $scr_hello );
}

######################################################################

STRICT_VARS: {
  local $^W; # Try to avoid an unecessary warning on 5.005_04
  my $scr_re = '% $foo ++; ';
  ok( ! eval { execute($scr_re); 1 } );
}

######################################################################

MULTILINE_STATEMENT_BLOCK: {
  
  my $scr_hash = <<'ENDSCRIPT';
<%perl>
 my %thing = (
    name => "disturbance",
    rank => "major",
    serial => "2"
 );
</%perl>
<table>
% foreach my $key (sort keys %thing) {
 <tr>
  <th><% $key %></th>
  <td><% $thing{$key} %></td>
 </tr>
% }
</table>
ENDSCRIPT

  my $res_hash = <<'ENDSCRIPT';
<table>
 <tr>
  <th>name</th>
  <td>disturbance</td>
 </tr>
 <tr>
  <th>rank</th>
  <td>major</td>
 </tr>
 <tr>
  <th>serial</th>
  <td>2</td>
 </tr>
</table>
ENDSCRIPT

  ok my $test_result = execute($scr_hash);  
  ok ($test_result, $res_hash);

}

######################################################################

MULTILINE_STATEMENT: {
  
  my $scr_hash = <<'ENDSCRIPT';
% my %thing = (
%    name => "mills",
%    rank => "general",
%    serial => "1"
% );
<table>
% foreach my $key (sort keys %thing) {
 <tr>
  <th><% $key %></th>
  <td><% $thing{$key} %></td>
 </tr>
% }
</table>
ENDSCRIPT

  my $res_hash = <<'ENDSCRIPT';
<table>
 <tr>
  <th>name</th>
  <td>mills</td>
 </tr>
 <tr>
  <th>rank</th>
  <td>general</td>
 </tr>
 <tr>
  <th>serial</th>
  <td>1</td>
 </tr>
</table>
ENDSCRIPT

  ok my $test_result = execute($scr_hash);  
  ok ($test_result, $res_hash);

}

######################################################################

