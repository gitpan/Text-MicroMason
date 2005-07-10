#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 8 }

my $loaded;
END { ok(0) unless $loaded; }

use Text::MicroMason;

my $mason_class = Text::MicroMason->class();

my $m = $mason_class->new();

ok( $loaded = 1 );

######################################################################

{

my $scr_hello = <<'ENDSCRIPT';
% my $noun = 'World';
Hello <% $noun %>!
How are ya?
ENDSCRIPT

my $res_hello = <<'ENDSCRIPT';
Hello World!
How are ya?
ENDSCRIPT

ok( $m->execute( text => $scr_hello), $res_hello );

ok( $m->compile( text => $scr_hello)->(), $res_hello );

my $scriptlet;
ok( ( $scriptlet = $m->compile( text => $scr_hello) ) and 1 );
ok( $scriptlet->(), $res_hello );
}

######################################################################

{
my $scr_bold = '<b><% $ARGS{label} %></b>';
ok( $m->execute( text => $scr_bold, label=>'Foo'), '<b>Foo</b>' );
ok( $m->compile( text => $scr_bold)->(label=>'Foo'), '<b>Foo</b>' );
}

######################################################################

{
  my $scr_mobj = 'You\'ve been compiled by <% ref $m %>.';
  
  my $res_mobj = 'You\'ve been compiled by Text::MicroMason';
  
  ok( $m->execute( text => $scr_mobj) =~ /^\Q$res_mobj\E/ );
}

######################################################################
