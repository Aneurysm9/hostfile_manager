package Hostfile::Manager;

use strict;
use warnings;
use Moose;
use File::Slurp;
use File::Find;
use File::Basename qw/dirname/;

our $VERSION = '0.3';

has path_prefix => ( is => 'rw', isa => 'Str', default => '/etc/hostfiles/' );
has hostfile_path => ( is => 'rw', isa => 'Str', default => '/etc/hosts' );
has hostfile => ( is => 'ro', isa => 'Str', writer => '_set_hostfile', lazy => 1, builder => 'load_hostfile', init_arg => undef );
has blocks => ( is => 'ro', isa => 'HashRef', default => sub { {} } );

sub load_hostfile {
	my ($self, $filename) = @_;

	$filename = $self->hostfile_path unless defined $filename;

	unless (-e $filename)
	{
		Carp::croak("Hostfile must exist.  File not found at $filename");
	}

	$self->_set_hostfile(read_file($filename));
}

sub write_hostfile {
	my $self = shift;

	my $filename = $self->hostfile_path;

	unless ((!-e $filename && -w dirname($filename))|| -w $filename)
	{
		Carp::croak("Unable to write hostfile to $filename");
	}

	write_file($filename, $self->hostfile);
}

sub get_fragment {
	my ($self, $fragment_name) = @_;

	my $filename = $self->path_prefix . $fragment_name;

	unless (-e $filename)
	{
		Carp::croak("Fragment not found at $filename");
	}

	read_file($filename);
}

sub fragment_enabled {
	my ($self, $fragment_name) = @_;

	$self->hostfile =~ @{[$self->block($fragment_name)]};
}

sub block {
	my ($self, $block_name) = @_;

	$self->blocks->{$block_name} ||= qr/(?:#+[\r\n])?#+\s*BEGIN: $block_name[\r\n](?:#+[\r\n])?(.*)(?:#+[\r\n])?#+\s*END: $block_name[\r\n](?:#+[\r\n])?/ms;
	return $self->blocks->{$block_name};
}

no Moose;
__PACKAGE__->meta->make_immutable;
