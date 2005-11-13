#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 23 }

my $loaded;
END { ok(0) unless $loaded; }

use Text::MicroMason;

my $m = Text::MicroMason->new();

ok( $loaded = 1 );

######################################################################

MINIMAL_CASES: {
  ok( $m->execute( text => ''), '' );
  ok( $m->execute( text => ' '), ' ' );
  ok( $m->execute( text => "0"), "0" );
  ok( $m->execute( text => "\n"), "\n" );
}

######################################################################

COMMENT_EXPR: {
  my $scr_re = 'Hello <% # foo %> World!';
  my $res_re = "Hello  World!";
  ok( $m->execute( text => $scr_re), $res_re );
}

######################################################################

EMPTY_PERL_LINE: {
  my $scr_re = "x\n%\nx";
  my $res_re = "x\nx";
  ok( $m->execute( text => $scr_re), $res_re );
}

######################################################################

COMMENT_PERL_LINE: {
  my $scr_re = "x\n% # \nx";
  my $res_re = "x\nx";
  ok( $m->execute( text => $scr_re), $res_re );
}

######################################################################

SINGLE_PERL_LINE: {
  my $scr_re = '% $_out->("Potato"); ';
  my $res_re = "Potato";
  ok( $m->execute( text => $scr_re), $res_re );
}

######################################################################

EMPTY_PERL_BLOCK: {
  my $scr_re = '<%perl></%perl>';
  ok( $m->execute( text => $scr_re), '' );
}

######################################################################

SINGLE_PERL_BLOCK: {
  my $scr_re = '<%perl> my $x = time(); </%perl>';
  ok( $m->execute( text => $scr_re), '' );
}

######################################################################

MULTISTATEMENT_EXPR_BLOCK: {
  my $scr_re = '<% my $x = time(); $x %>';
  ok( $m->execute( text => $scr_re), time() );
}

######################################################################

MULTIPLE_PERL_BLOCKS: {
  my $scr_re = '<%perl> my $x = time(); if (0) { </%perl> <%perl> } </%perl>';
  ok( $m->execute( text => $scr_re), '' );
}

######################################################################

SINGLE_PERL_LINE_NEWLINES: {
  my $scr_re = "\n" . '% $_out->("Potato"); ' . "\n\n";
  my $res_re = "\nPotato\n";
  ok( $m->execute( text => $scr_re), $res_re );
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
  
  ok( $m->execute( text => $scr_hello), $res_hello );
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
  
  ok( $m->execute( text => $scr_hello, name => 'Bob'), $res_hello );
  ok( $m->compile( text => $scr_hello)->( name => 'Bob' ), $res_hello );
}

######################################################################

PERL_BLOCK_AT_EOF: {
  my $scr_hello = 'Hello World<%perl>my $x = time();</%perl>';
  
  my $res_hello = 'Hello World';
  
  ok( $m->execute( text => $scr_hello), $res_hello );
}

######################################################################

ANGLE_PERCENT_BLOCK_AT_EOF: {
  my $scr_hello = '% my $noun = "World";' . "\n" . 'Hello <% $noun %>';
  
  my $res_hello = 'Hello World';
  
  ok( $m->execute( text => $scr_hello), $res_hello );
}

######################################################################

FILE_BLOCK_AT_EOF: {
  my $scr_hello = "<& 'samples/test-recur.msn', name => 'Dave' &>";
  
  my $res_hello = "Test greeting:\n" . 'Good afternoon, Dave!' . "\n";
  
  ok( $m->execute( text => $scr_hello), $res_hello );
}

######################################################################

LOOKS_LIKE_HTML: {
  my $scr_hello = '<TABLE border="1" width="100%"><tr><td>Hi</td></tr></table>';

  ok( $m->execute( text => $scr_hello), $scr_hello );
}

######################################################################

STRICT_VARS: {
  local $^W; # Try to avoid an unecessary warning on 5.005_04
  my $scr_re = '% $foo ++; ';
  ok( ! eval { $m->execute( text => $scr_re); 1 } );
}

######################################################################

FILE_BLOCK_MULTILINE: {
  my $scr_hello = "<& \n 'samples/test-recur.msn', name => 'Dave' \n &>";
  
  my $res_hello = "Test greeting:\n" . 'Good afternoon, Dave!' . "\n";
  
  ok( $m->execute( text => $scr_hello), $res_hello );
}

######################################################################
