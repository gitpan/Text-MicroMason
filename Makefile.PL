use ExtUtils::MakeMaker;

########################################################################

WriteMakefile(
              NAME         => 'Text::MicroMason',
              VERSION_FROM => 'MicroMason.pm',
              PREREQ_PM    => {
                                 'Class::MixinFactory' => 0.9,
                              },

              ABSTRACT_FROM     => 'MicroMason.pm', 
              AUTHOR            => 'Alan Ferrency <ferrency@cpan.org>',
              LICENSE           => 'perl',
);

########################################################################

sub MY::postamble { q{

fresh: realclean FORCE
	perl Makefile.PL

again: realclean FORCE
	perl Makefile.PL; make pm_to_blib

cleanmanifest: realclean FORCE
	touch MANIFEST ; rm MANIFEST ; perl Makefile.PL; touch MANIFEST; make manifest

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

####
# Notes, building a distribution
#
#   perl Makefile.PL
#   make docs
#   make cleanmanifest
#   make disttest
#   make dist
