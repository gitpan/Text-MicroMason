#!/usr/bin/perl -w

use strict;
use Test;

# Test the potential conflict between CompileCache and
# TemplateDir options

BEGIN { plan tests => 5 }

use Text::MicroMason;
my $m1 = Text::MicroMason->new( -CompileCache, -TemplateDir, template_root => 'samples/' );
my $m2 = Text::MicroMason->new( -CompileCache, -TemplateDir, template_root => 'samples/subdir' );

######################################################################
#
# In the m2 object, using the samples/subdir, we should get an answer in German.

SUBDIR: {
  my $output = $m2->execute( file=>'test.msn', name=>'Sam', hour=>14);
  ok( $output =~ /\QGuten Tag, Sam!\E/ );

  $output = $m2->execute( file=>'test.msn', name=>'Sam', hour=>10);
  ok( $output =~ /\QGuten Morgen, Sam!\E/ );
}

# And, if we execute test.msn in m1, we should get an answer in English.

FILE: {
  my $output = $m1->execute( file=>'test.msn', name=>'Sam', hour=>14);
  ok( $output =~ /\QGood afternoon, Sam!\E/ );

  $output = $m1->execute( file=>'test.msn', name=>'Sam', hour=>10);
  ok( $output =~ /\QGood morning, Sam!\E/ );
}


my $m = Text::MicroMason->new( -TemplateDir, template_root => 'samples/' );

RELATIVE: {
  my $scr_hello = $m->execute( file => 'test-relative.msn', name => 'Dave');
  my $res_hello = "Test greeting:\nGood afternoon, Dave!\n";
  ok( $m->execute(text=>$scr_hello), $res_hello );
}
