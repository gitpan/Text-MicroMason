use ExtUtils::MakeMaker;

########################################################################

WriteMakefile(
    'NAME'         => 'Text::MicroMason',
    'VERSION_FROM' => 'MicroMason.pm',
    'PREREQ_PM'    => {}, 

    test => { TESTS => undef },

    ($] >= 5.005 ? (
      ABSTRACT_FROM     => 'MicroMason.pm', 
      AUTHOR            => 'Matthew Simon Cavalletto <simonm@cavalletto.org>',
    ) : ()),
);

########################################################################

sub MY::postamble { q{

again: realclean FORCE
	perl Makefile.PL; make pm_to_blib

cleanmanifest: realclean FORCE
	rm MANIFEST ; perl Makefile.PL; touch MANIFEST; make manifest

%.t: pm_to_blib FORCE
	make; perl -Iblib/lib $@

cover: FORCE
	cover -delete; HARNESS_PERL_SWITCHES=-MDevel::Cover make test; cover

docs : README CHANGES TODO

README: MicroMason/Docs/ReadMe.pod
	pod2text MicroMason/Docs/ReadMe.pod > README

CHANGES: MicroMason/Docs/Changes.pod
	pod2text MicroMason/Docs/Changes.pod > CHANGES

TODO: MicroMason/Docs/ToDo.pod
	pod2text MicroMason/Docs/ToDo.pod > TODO

}; }
