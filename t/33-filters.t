#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 14 }

use Text::MicroMason;

my $m = Text::MicroMason->new( -Filters );

my $res_nofilter = 'Hello <"world">!';

######################################################################
# Test default h encoding flag if we have HTML::Entities
my $h = HTML::Entities->can('encode');
my $src_h = q(Hello <% '<"world">' |h %>!);
my $res_h = 'Hello &lt;&quot;world&quot;&gt;!';

skip ( $h ? 0 : "Test uses HTML::Entities", sub { $m->execute( text=> $src_h) }, $res_h);

# Test h as a default filter
{
    local $m->{default_filters} = 'h';
    my $src_h2 = q(Hello <% '<"world">' %>!);
    skip ( $h ? 0 : "Test uses HTML::Entities", sub { $m->execute( text => $src_h2) }, $res_h);

# Explicitly disable the default filters
    my $src_h3 = q(Hello <% '<"world">' | n %>!);
    skip ( $h ? 0 : "Test uses HTML::Entities", sub { $m->execute( text => $src_h3) }, $res_nofilter);
}

######################################################################
# Test default u encoding flag if we have URI::Escape
my $u = URI::Escape->can('uri_escape');

my $res_u = 'Hello %3C%22world%22%3E!';

my $src_u1 = qq(Hello <% '<"world">' |u %>!);
skip ( $u ? 0 : "Test uses URI::Escape", sub { $m->execute( text=> $src_u1) }, $res_u);

# Test u as a default filter
{
    local $m->{default_filters} = 'u';
    my $src_u2 = qq(Hello <% '<"world">' %>!);
    skip ( $u ? 0 : "Test uses URI::Escape", sub { $m->execute( text => $src_u2) }, $res_u);

# Explicitly disable the default filters
    my $src_u3 = qq(Hello <% '<"world">' | n %>!);
    my $res_u3 = 'Hello <"world">!';
    skip ( $u ? 0 : "Test uses URI::Escape", sub { $m->execute( text => $src_u3) }, $res_nofilter);
}


######################################################################

# Test stacking and canceling with n
{
  my $src_unh = qq(Hello <% '<"world">' |unh %>!);
  my $res_unh = 'Hello &lt;&quot;world&quot;&gt;!';
  skip ( $h ? 0 : "Test uses HTML::Entities", sub { $m->execute( text => $src_unh) }, $res_unh);

  my $res_hnu = 'Hello %3C%22world%22%3E!';  
  my $src_hnu = qq(Hello <% '<"world">' |hnu %>!);
  skip ( $u ? 0 : "Test uses URI::Escape", sub { $m->execute( text => $src_hnu) }, $res_hnu);
}


######################################################################
# Test custom filters

sub f1 {
    $_ = shift;
    tr/elo/apy/;
    $_;
}

sub f2 {
    $_ = shift;
    s/wyrpd/birthday/;
    $_;
}

$m->filter_functions( f1 => \&f1 );
$m->filter_functions( f2 => \&f2 );

# Try one custom filter

my $src_custom1 = qq(<% 'hello <"world">' | f1 %>);
my $res_custom1 = qq(happy <"wyrpd">);
ok ($m->execute( text => $src_custom1), $res_custom1);

# Try two filters in order: they're order dependant, so this will fail
# if they execute in the wrong order.

my $src_custom2 = qq(<% 'hello <"world">' | f1 , f2 %>);
my $res_custom2 = qq(happy <"birthday">);
ok ($m->execute( text => $src_custom2), $res_custom2);


# Try both filters as defaults
{
    local $m->{default_filters} = 'f1, f2';
    my $src_custom3 = qq(<% 'hello <"world">' %>);
    ok ($m->execute( text => $src_custom3), $res_custom2);

# Override default filters
    my $src_custom4 = qq(<% 'hello <"world">' |n, f1 %>);
    ok ($m->execute( text => $src_custom4), $res_custom1);
}


# Try one default filter and one additional filter
{
    local $m->{default_filters} = 'f1';
    my $src_custom3 = qq(<% 'hello <"world">' %>);
    ok ($m->execute( text => $src_custom3), $res_custom1);

    my $src_custom4 = qq(<% 'hello <"world">' | f2 %>);
    ok ($m->execute( text => $src_custom4), $res_custom2);
}

