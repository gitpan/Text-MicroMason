use ExtUtils::MakeMaker;

########################################################################

WriteMakefile(
    'NAME'         => 'Text::MicroMason',
    'VERSION_FROM' => 'MicroMason.pm',
    'PREREQ_PM'    => {}, 

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

docs : README CHANGES

README: MicroMason/ReadMe.pod
	pod2text MicroMason/ReadMe.pod > README

CHANGES: MicroMason/Changes.pod
	pod2text MicroMason/Changes.pod > CHANGES

}; }
