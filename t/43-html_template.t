#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 5 }

my $loaded;
END { ok(0) unless $loaded; }

use Text::MicroMason;

my $m = Text::MicroMason->new( -HTMLTemplate, template_root => 'examples', 'debug' => 0 );
ok( $loaded = 1 );

######################################################################

my ($output, $template, $result);

# test a simple template
$template = $m->new( filename => 'simple.tmpl' );

$template->param( 'ADJECTIVE', 'very' );
$output = $template->output();
ok($output !~ /ADJECTIVE/ and $template->param('ADJECTIVE') eq 'very');

######################################################################

# test a simple loop template
$template = $m->new( filename => 'simple-loop.tmpl' );

$template->param('ADJECTIVE_LOOP', [ { ADJECTIVE => 'really' }, { ADJECTIVE => 'very' } ] );
$output = $template->output();
ok($output !~ /ADJECTIVE_LOOP/ and $output =~ /really.*very/s);

######################################################################

# test a simple if template
$template = $m->new( filename => 'if.tmpl' );
$output = $template->output();
ok($output !~ /INSIDE/);

# test a simple if template
$template = $m->new( filename => 'if.tmpl' );
$template->param(BOOL => 1);
$output = $template->output();
ok($output =~ /INSIDE/);

######################################################################
