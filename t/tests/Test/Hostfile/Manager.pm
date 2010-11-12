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

	my $default_prefix = '/etc/hostfiles/';
	my $new_prefix = '/etc/hostfiles/2/';

	can_ok $manager, 'path_prefix';
	is $default_prefix, $manager->path_prefix, '... and path_prefix should start out with default value';

	$manager->path_prefix($new_prefix);
	is $manager->path_prefix, $new_prefix, '... and setting its value should succeed';
}

sub hostfile_path: Tests(3) {
	my $test = shift;
	my $manager = $test->class->new;

	my $default_hostfile_path = '/etc/hosts';
	my $new_hostfile_path = '/etc/hosts2';

	can_ok $manager, 'hostfile_path';
	is $default_hostfile_path, $manager->hostfile_path, '... and hostfile_path should start out with default value';

	$manager->hostfile_path($new_hostfile_path);
	is $manager->hostfile_path, $new_hostfile_path, '... and setting its value should succeed';
}

sub hostfile: Tests(4) {
	my $test = shift;

	my $file = 't/fixtures/hosts/1';
	my $content = read_file($file);

	my $manager = $test->class->new(hostfile_path => $file);

	can_ok $manager, 'hostfile';
	is $content, $manager->hostfile, '... and hostfile should start out with content of file at hostfile_path';
	throws_ok { $manager->hostfile('foobar') } qr/^Cannot assign a value/, '... and settings its value should NOT succeed';
	is $content, $manager->hostfile, '... and settings its value did not succeed';
}

sub hostfile_is_lazy: Tests(2) {
	my $test = shift;

	my $file = 't/fixtures/hosts/1';
	my $content = read_file($file);

	my $manager = $test->class->new(hostfile_path => 'non_existent');
	$manager->hostfile_path($file);

	can_ok $manager, 'hostfile';
	is $content, $manager->hostfile, '... and hostfile should start out with content of file at hostfile_path, even when constructed with a different hostfile_path';
}

sub hostfile_cannot_be_set_in_constructor: Tests(1) {
	my $test = shift;

	my $file = 't/fixtures/hosts/1';
	my $content = read_file($file);

	my $manager = $test->class->new(hostfile_path => $file, hostfile => 'this should be ignored');

	is $content, $manager->hostfile, 'hostfile should start out with content of file at hostfile_path';
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

sub load_hostfile_requires_hostfile_existence: Tests(2) {
	my $test = shift;
	my $manager = $test->class->new;

	my $file = 't/fixtures/hosts/non_existent';

	can_ok $manager, 'load_hostfile';
	throws_ok { $manager->load_hostfile($file) } qr/^Hostfile must exist/, '... and load_hostfile chokes when hostfile missing';
}

sub get_fragment: Tests(2) {
	my $test = shift;

	my $hostfile = 't/fixtures/hosts/1';
	my $prefix = 't/fixtures/fragments/';
	my $fragment = 'f1';

	my $manager = $test->class->new(path_prefix => $prefix, hostfile_path => $hostfile);

	can_ok $manager, 'get_fragment';
	is read_file($prefix . $fragment), $manager->get_fragment($fragment), '... and get_fragment returns fragment content';
}

sub get_fragment_requires_fragment_existence: Tests(2) {
	my $test = shift;

	my $hostfile = 't/fixtures/hosts/1';
	my $prefix = 't/fixtures/fragments/';
	my $fragment = 'non_existent';

	my $manager = $test->class->new(path_prefix => $prefix, hostfile_path => $hostfile);

	can_ok $manager, 'get_fragment';
	throws_ok { $manager->get_fragment($fragment) } qr/^Fragment not found/, '... and get_fragment chokes when fragment file missing';
}

sub block: Tests(2) {
	my $test = shift;
	my $manager = $test->class->new;

	my $fragment_name = 'f1';
	my $block_regexp = qr/(?:#+[\r\n])?#+\s*BEGIN: $fragment_name[\r\n](?:#+[\r\n])?(.*)(?:#+[\r\n])?#+\s*END: $fragment_name[\r\n](?:#+[\r\n])?/ms;

	can_ok $manager, 'block';
	is $block_regexp, $manager->block($fragment_name);
}

sub write_hostfile: Tests(3) {
	my $test = shift;
	my $manager = $test->class->new;

	my $file = 't/fixtures/hosts/1';
	my $content = read_file($file);

	$manager->load_hostfile($file);

	can_ok $manager, 'write_hostfile';

	my $file2 = 't/fixtures/hosts/write_test';
	unlink($file2);

	$manager->hostfile_path($file2);
	ok $manager->write_hostfile, '... and write_hostfile returns ok';
	is $content, read_file($file2), "... and hostfile written to $file2";

	unlink($file2);
}

sub write_hostfile_requires_writable: Tests(3) {
	my $test = shift;
	my $manager = $test->class->new;

	my $file = 't/fixtures/hosts/1';
	my $content = read_file($file);

	$manager->load_hostfile($file);

	can_ok $manager, 'write_hostfile';

	my $file2 = 't/fixtures/hosts/write_test';
	write_file($file2, '');
	chmod 0444, $file2;

	$manager->hostfile_path($file2);
	throws_ok { $manager->write_hostfile} qr/^Unable to write hostfile/, '... and write_hostfile chokes when trying to write to file without permissions';
	is '', read_file($file2), "... and hostfile written to $file2";

	unlink($file2);
}

sub fragment_enabled: Tests(3) {
	my $test = shift;

	my $path = 't/fixtures/hosts/2';
	my $prefix = 't/fixtures/fragments/';
	my $manager = $test->class->new(hostfile_path => $path, path_prefix => $prefix);

	can_ok $manager, 'fragment_enabled';
	ok $manager->fragment_enabled('f1'), '... and fragment_enabled returns ok when fragment is indeed enabled';
	not ok $manager->fragment_enabled('f2'), '... and fragment_enabled returns not_ok when fragment is not enabled';
}
1;
