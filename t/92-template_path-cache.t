#!/usr/bin/perl -w

use strict;
use Test;

# Test TemplatePath with CompileCache

BEGIN { plan tests => 8 }

use Text::MicroMason;

######################################################################
#
# Compile and cache test-relative.msn with one path. Executing it again
# with a different path should get us different results.

my $m1 = Text::MicroMason->new( -CompileCache,
                                -TemplatePath, template_path => [ qw(samples/subdir/ samples/) ]);
PATH1: {
    ok (my $scr_hello = $m1->execute( file => 'test-relative.msn', name => 'Dave'));
    ok (my $res_hello = "Test greeting:\nGuten Tag, Dave!\n");
    ok ($scr_hello =~ /\Q$res_hello\E/);
    ok ($m1->execute(text => $scr_hello) =~ /\Q$res_hello\E/);
}

my $m2 = Text::MicroMason->new( -CompileCache,
                                -TemplatePath, template_path => [ qw(samples/ samples/subdir/) ]);

PATH2: {
    ok (my $scr_hello = $m2->execute( file => 'test-relative.msn', name => 'Dave'));
    ok (my $res_hello = "Test greeting:\nGood afternoon, Dave!\n");
    ok ($scr_hello =~ /\Q$res_hello\E/);
    ok ($m2->execute(text => $scr_hello) =~ /\Q$res_hello\E/);
}


