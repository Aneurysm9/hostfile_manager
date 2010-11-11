package Hostfile::Manager;

use strict;
use warnings;
use File::Slurp;
use File::Find;

BEGIN {
	use Exporter ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK);

	$VERSION = '0.2';
	@ISA = qw(Exporter);
	@EXPORT = qw(disable_fragments enable_fragments read_hostfile show_status write_hostfile);
}

my %re;
my $path_prefix = '/etc/hostfiles/';
my $hostfile_path = '/etc/hosts';
my $hostfile;

sub block
{
	my $name = shift;
	$re{$name} ||= qr/(?:#+[\r\n])?#+\s*BEGIN: $name[\r\n](?:#+[\r\n])?(.*)(?:#+[\r\n])?#+\s*END: $name[\r\n](?:#+[\r\n])?/ms;
	return $re{$name};
}

sub enable_fragments
{
	my @enabled = @_;
	foreach my $enable (@enabled)
	{
		my $filename = $path_prefix . $enable;
		unless (-e $filename)
		{
			print "Hostfile fragment $enable does not exist\n";
			next;
		}

		print "Enabling $enable\n";
		$hostfile =~ s/@{[block($enable)]}//g;

		my $addition = read_file($filename);
		$hostfile .= "# BEGIN: $enable\n$addition# END: $enable\n\n";
	}
}

sub disable_fragments
{
	my @disabled = @_;
	foreach my $disable (@disabled)
	{
		print "Disabling $disable\n";
		$hostfile =~ s/@{[block($disable)]}//g;
	}
}

sub read_hostfile
{
	die("You must have permission to read $hostfile_path\n") unless (-r $hostfile_path);
	$hostfile = read_file($hostfile_path);
}

sub show_status
{
	find(\&status_helper, $path_prefix);
}

sub status_helper
{
	my $fragment = $File::Find::name;
	return if -d $fragment;

	my $fragment_contents = read_file($fragment);
	$fragment =~ s{^$path_prefix}{};

	my $found = $hostfile =~ /@{[block($fragment)]}/;
	my $flag = $found ? ($1 eq "$fragment_contents\n" ? "+" : "*") : " ";
	print "$flag $fragment\n";
}

sub write_hostfile
{
	die("You must have permission to write $hostfile_path\n") unless (-w $hostfile_path);
	write_file($hostfile_path, $hostfile);
}

1;
