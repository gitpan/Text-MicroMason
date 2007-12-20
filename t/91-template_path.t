#!/usr/bin/perl -w

use strict;
use Test;

# Test TemplatePath

BEGIN { plan tests => 11 }

use Text::MicroMason;

######################################################################

my $m1 = Text::MicroMason->new( -TemplatePath, template_path => [ qw(samples/subdir/ samples/) ]);

# If we execute a template in subdir/ we should get it (and not the
# samples/ version).

SUBDIR: {
    ok (my $output = $m1->execute( file => 'test.msn', name => 'Sam', hour => 14));
    ok ($output =~ /\QGuten Tag, Sam!\E/);
    
    ok ($output = $m1->execute( file => 'test.msn', name=>'Sam', hour=>10));
    ok ($output =~ /\QGuten Morgen, Sam!\E/);
}

# If we call a template that only exists in samples/ then that should
# work as well.  But the referred template 

SAMPLE: {
    ok (my $scr_hello = $m1->execute( file => 'test-relative.msn', name => 'Dave'));
    ok (my $res_hello = "Test greeting:\nGuten Tag, Dave!\n");
    ok ($scr_hello =~ /\Q$res_hello\E/);
    ok ($m1->execute(text => $scr_hello) =~ /\Q$res_hello\E/);
}


######################################################################
# With the reverse path we should get opposite results.

my $m2 = Text::MicroMason->new( -TemplatePath, template_path => [ qw(samples/ samples/subdir/) ]);

SUBDIR: {
    my $output = $m2->execute( file=>'test.msn', name=>'Sam', hour=>14);
    ok( $output =~ /\QGood afternoon, Sam!\E/ );
    
    $output = $m2->execute( file=>'test.msn', name=>'Sam', hour=>10);
    ok( $output =~ /\QGood morning, Sam!\E/ );
}

# If we call a template that only exists in samples/ then that should
# work as well.  But the referred template 

SAMPLE: {
    my $scr_hello = $m2->execute( file => 'test-relative.msn', name => 'Dave');
    my $res_hello = "Test greeting:\nGood afternoon, Dave!\n";
    ok( $m2->execute(text=>$scr_hello), $res_hello );
}


