use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'Hostfile::Manager',
	VERSION_FROM => 'lib/Hostfile/Manager.pm',
	EXE_FILES => ['bin/hostfiles'],
	PREREQ_PM => {
		'Getopt::Long' => 0,
		'File::Find' => 0,
		'File::Slurp' => 0,
		'Pod::Usage' => 0,
	},
	AUTHOR => 'Anthony J. Mirabella',
);
