use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'Hostfile::Manager',
	VERSION_FROM => 'lib/Hostfile/Manager.pm',
	EXE_FILES => ['bin/hostfiles'],
	PREREQ_PM => {
		'File::Basename' => 0,
		'File::Find' => 0,
		'File::Slurp' => 0,
		'Getopt::Long' => 0,
		'Moose' => 0,
		'Pod::Usage' => 0,
		'Term::Clui' => 0,
		'Test::Class' => 0,
		'Test::Most' => 0,
		'Test::NoWarnings' => 0,
	},
	AUTHOR => 'Anthony J. Mirabella',
);
