#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 10 }

use Text::MicroMason;

######################################################################

LC: {
  my $m = Text::MicroMason->new( -PostProcess );
  $m->post_processors( sub { lc } );
  my $output = $m->execute( text=>'Hello there!' );
  ok( $output, 'hello there!' );
}

######################################################################

UC_NEW: {
  my $m = Text::MicroMason->new( -PostProcess, post_process => sub { uc } );
  my $output = $m->execute( text=>'Hello there!' );
  ok( $output, 'HELLO THERE!' );
}

UC_PPMETH: {
  my $m = Text::MicroMason->new( -PostProcess );
  $m->post_processors( sub { uc } );
  my $output = $m->execute( text=>'Hello there!' );
  ok( $output, 'HELLO THERE!' );
}

UC_COMPILE: {
  my $m = Text::MicroMason->new( -PostProcess );
  my $subdef = $m->compile( text=>'Hello there!', post_process => sub { uc } );
  my $output = &$subdef();
  ok( $output, 'HELLO THERE!' );
}

UC_EXECUTE: {
  my $m = Text::MicroMason->new( -PostProcess );
  my $output = $m->execute( text=>'Hello there!', { post_process => sub { uc } } );
  ok( $output, 'HELLO THERE!' );
}

######################################################################

sub f1 {
    $_ = shift;
    tr/elo/apy/;
    $_;
}

sub f2 {
    $_ = shift;
    s/ello/ola/;
    s/wyrpd/birthday/;
    $_;
}

ORDERED_F1: {
  my $m = Text::MicroMason->new( -PostProcess, post_process => \&f1 );
  my $output = $m->execute( text=>'Hello world!' );
  ok( $output, 'Happy wyrpd!' );
}

ORDERED_F2: {
  my $m = Text::MicroMason->new( -PostProcess, post_process => \&f2 );
  my $output = $m->execute( text=>'Hello world!' );
  ok( $output, 'Hola world!' );
}

ORDERED_F1F2: {
  my $m = Text::MicroMason->new( -PostProcess, post_process => [ \&f1, \&f2 ] );
  my $output = $m->execute( text=>'Hello world!' );
  ok( $output, 'Happy birthday!' );
}

ORDERED_F2F1: {
  my $m = Text::MicroMason->new( -PostProcess, post_process => [ \&f2, \&f1 ] );
  my $output = $m->execute( text=>'Hello world!' );
  ok( $output, 'Hypa wyrpd!' );
}

######################################################################

sub naf1 () {
    tr/elo/apy/;
}

sub naf2 () {
    s/ello/ola/;
    s/wyrpd/birthday/;
}

EMPTY_PROTOTYPES: {
  my $m = Text::MicroMason->new( -PostProcess );
  $m->post_processors( \&naf1 );
  $m->post_processors( \&naf2 );
  my $output = $m->execute( text=>'Hello world!' );
  ok( $output, 'Happy birthday!' );
}

######################################################################
