#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 10 }

my $loaded;
END { ok(0) unless $loaded; }

use Text::MicroMason;

my $m = Text::MicroMason->new( -TextTemplate );

ok( $loaded = 1 );

######################################################################

my $scr_hello = <<'ENDSCRIPT';
Dear {$recipient},
Pay me at once.
      Love, 
	G.V.
ENDSCRIPT

my $res_hello = <<'ENDSCRIPT';
Dear King,
Pay me at once.
      Love, 
	G.V.
ENDSCRIPT

ok( $m->execute( text => $scr_hello, recipient => 'King' ), $res_hello );

ok( $m->compile( text => $scr_hello)->( recipient => 'King' ), $res_hello );

######################################################################

{ no strict;

$source = 'We will put value of $v (which is "good") here -> {$v}';
$v = 'oops (main)';
$Q::v = 'oops (Q)';
$vars = { 'v' => \'good' };

# (1) Build template from string
$template = $m->compile( 'text' => $source );
ok( ref $template );

# (2) Fill in template in anonymous package
$result2 = 'We will put value of $v (which is "good") here -> good';
$text = $template->(%$vars);
ok($text, $result2);

# (3) Did we clobber the main variable?
ok($v, 'oops (main)');

# (4) Fill in same template again
$result4 = 'We will put value of $v (which is "good") here -> good';
$text = $template->(%$vars);
ok($text, $result4);

# (5) Now with a package
$result5 = 'We will put value of $v (which is "good") here -> good';
$template = $m->new(package => 'Q')->compile( 'text' => $source );
$text = $template->(%$vars);
ok($text, $result5);

# (6) We expect to have clobbered the Q variable.
ok($Q::v, 'good');

# (7) Now let's try it without a package
$result7 = 'We will put value of $v (which is "good") here -> good';
$template = $m->new()->compile( 'text' => $source );
$text = $template->(%$vars);
ok($text, $result7);
}

######################################################################
