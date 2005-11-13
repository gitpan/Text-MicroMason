#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 16 }

my $loaded;
END { ok(0) unless $loaded; }

use Text::MicroMason;

my $m = Text::MicroMason->new( -QuickTemplate );

ok( $loaded = 1 );

######################################################################

my $scr_hello = <<'ENDSCRIPT';
Dear {{to}},
    Have a {{day_type}} day.
Your {{relation}},
{{from}}
ENDSCRIPT

my $res_hello = <<'ENDSCRIPT';
Dear Professor Dumbledore,
    Have a swell day.
Your friend,
Harry
ENDSCRIPT

my $scriptlet;
ok( ( $scriptlet = $m->compile( text => $scr_hello) ) and 1 );
ok( $scriptlet->(to       => 'Professor Dumbledore',
         relation => 'friend',
         day_type => 'swell',
         from     => 'Harry',), $res_hello );

ok( $scriptlet->( { to       => 'Professor Dumbledore',
         relation => 'friend',
         day_type => 'swell',
         from     => 'Harry', } ), $res_hello );

######################################################################

my $emulator;
ok( ( $emulator = $m->new( text => $scr_hello) ) and 1 );
ok( $emulator->fill( { to       => 'Professor Dumbledore',
         relation => 'friend',
         day_type => 'swell',
         from     => 'Harry', } ), $res_hello );

######################################################################

my $book_t = $emulator->new( text => '<i>{{title}}</i>, by {{author}}' );

my $bibl_1 = $book_t->fill({author => "Stephen Hawking",
                          title  => "A Brief History of Time"});
ok( $bibl_1 eq "<i>A Brief History of Time</i>, by Stephen Hawking" );

my $bibl_2 = $book_t->fill({author => "Dr. Seuss",
			title  => "Green Eggs and Ham"});
ok( $bibl_2, "<i>Green Eggs and Ham</i>, by Dr. Seuss" );

######################################################################

my $bibl_3 = eval { $book_t->fill({author => 'Isaac Asimov'}) };
ok( ! defined $bibl_3 );
ok( $@ =~ "could not resolve the following symbol: title" );

######################################################################

use Text::MicroMason::QuickTemplate;

my $bibl_4 = $book_t->fill({author => 'Isaac Asimov',
			title  => $DONTSET });
ok( $bibl_4, "<i>{{title}}</i>, by Isaac Asimov" );

######################################################################

ok( ( $m->compile( text => $scr_hello) ) and 1 );
ok( $m->pre_fill(to       => 'Professor Dumbledore',
         relation => 'friend' ) );

ok( ! eval { $m->fill(); 1 } );

ok( $m->pre_fill( day_type => 'swell',
         from     => 'Harry') );
ok( $m->fill(), $res_hello );

######################################################################
