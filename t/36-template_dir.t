#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 3 }

use Text::MicroMason;
my $m = Text::MicroMason->new( -CatchErrors, -TemplateDir, template_root => 'examples/' );

######################################################################

FILE: {
  my $output = $m->execute( file=>'test.msn', name=>'Sam', hour=>14);
  ok( $output =~ /\QGood afternoon, Sam!\E/ );
}

######################################################################

TAG: {
  my $scr_hello = "<& 'test-relative.msn', name => 'Dave' &>";
  my $res_hello = "Test greeting:\n" . 'Good afternoon, Dave!' . "\n";
  warn( ( $m->execute(text=>$scr_hello) )[1] ."\n" );
  ok( $m->execute(text=>$scr_hello), $res_hello );
}

######################################################################

BASE: {
  my $m = Text::MicroMason->new( -CatchErrors, -TemplateDir );
  my $scr_hello = "<& 'examples/test-relative.msn', name => 'Dave' &>";
  my $res_hello = "Test greeting:\n" . 'Good afternoon, Dave!' . "\n";
  ok( $m->execute(text=>$scr_hello), $res_hello );
}

######################################################################
