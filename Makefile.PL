use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'Filter::Include',
    'VERSION_FROM'  => 'Include.pm', # finds $VERSION
    'PREREQ_PM'     => {
      'Regexp::Common' => 0.01,
    },
);
