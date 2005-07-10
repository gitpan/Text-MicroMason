#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 6 }

use Text::MicroMason;
my $m = Text::MicroMason->new( -CatchErrors );

######################################################################

FILE: {
  my $output = $m->execute( file=>'samples/test.msn', name=>'Sam', hour=>14);
  ok( $output =~ /\QGood afternoon, Sam!\E/ );
}

######################################################################

TAG: {
  my $scr_hello = "<& 'samples/test-recur.msn', name => 'Dave' &>";
  my $res_hello = "Test greeting:\n" . 'Good afternoon, Dave!' . "\n";
  ok( $m->execute(text=>$scr_hello), $res_hello );
}

######################################################################

SYNTAX: {
  my $script = <<'TEXT_END';

<%perl>
  my $hour = $ARGS{hour};
</%perl> xx
% if ( $ARGS{name} eq 'Dave' and $hour > 22 ) {
  I'm sorry <% $ARGS{name} %>, I'm afraid I can't do that right now.
% } else {
  <& 'samples/test.msn', name => $ARGS{name}, hour => $hour &>
% }
TEXT_END

  my $code = $m->compile( text=>$script);
  
  my ( $output, $error ) = $m->execute( code=>$code, name => 'Sam', hour => 9);
  ok( $output =~ /\QGood morning, Sam!\E/ );
  ok( ! $error );
  $output = $m->execute( code=>$code, name => 'Dave', hour => 23);
  ok( $output =~ /\Qsorry Dave\E/ );
}

######################################################################

HANDLE: {
  open TEST, 'samples/test.msn';
  my $output = $m->execute( handle => \*TEST, name=>'Sam', hour=>14);
  close TEST;
  ok( $output =~ /\QGood afternoon, Sam!\E/ );
}

######################################################################
