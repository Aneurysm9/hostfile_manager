package Test::Hostfile::Manager;

use Test::Most;
use File::Slurp;
use base 'Test::Class';

sub class { 'Hostfile::Manager'; }

sub startup : Tests(startup => 1) {
	my $test = shift;
	use_ok $test->class;
}

sub constructor : Tests(3) {
	my $test  = shift;
	my $class = $test->class;
	can_ok $class, 'new';
	ok my $manager = $class->new, '... and the constructor should succeed';
	isa_ok $manager, $class, '... and the object it returns';
}

sub path_prefix: Tests(3) {
	my $test = shift;
	my $manager = $test->class->new;

	can_ok $manager, 'path_prefix';
	ok !defined $manager->path_prefix, '... and path_prefix should start out undefined';

	my $prefix = '/etc/hostfiles/';
	$manager->path_prefix($prefix);
	is $manager->path_prefix, $prefix, '... and setting its value should succeed';
}

sub hostfile_path: Tests(3) {
	my $test = shift;
	my $manager = $test->class->new;

	can_ok $manager, 'hostfile_path';
	ok !defined $manager->hostfile_path, '... and hostfile_path should start out undefined';

	my $hostfile_path = '/etc/hosts';
	$manager->hostfile_path($hostfile_path);
	is $manager->hostfile_path, $hostfile_path, '... and setting its value should succeed';
}

sub hostfile: Tests(4) {
	my $test = shift;
	my $manager = $test->class->new;

	can_ok $manager, 'hostfile';
	ok !defined $manager->hostfile, '... and hostfile should start out undefined';
	throws_ok { $manager->hostfile('foobar') } qr/^Cannot assign a value/, '... and settings its value should NOT succeed';
	ok !defined $manager->hostfile, '... and settings its value did not succeed';

}

sub load_hostfile: Tests(3) {
	my $test = shift;
	my $manager = $test->class->new;

	my $file = 't/fixtures/hosts/1';
	my $content = read_file($file);

	can_ok $manager, 'load_hostfile';
	ok $manager->load_hostfile($file), '... and load_hostfile indicates success';
	is $content, $manager->hostfile, '... and load_hostfile actually loaded the file';
}

sub load_hostfile_uses_hostfile_path: Tests(3) {
	my $test = shift;
	my $manager = $test->class->new;

	my $file = 't/fixtures/hosts/1';
	my $content = read_file($file);
	$manager->hostfile_path($file);

	can_ok $manager, 'load_hostfile';
	ok $manager->load_hostfile, '... and load_hostfile indicates success';
	is $content, $manager->hostfile, '... and load_hostfile actually loaded the file';
}

1;
