package Hostfile::Manager;

use strict;
use warnings;
use Moose;
use File::Slurp;
use File::Find;

our $VERSION = '0.3';

has path_prefix => ( is => 'rw', isa => 'Str', default => '/etc/hostfiles/' );
has hostfile_path => ( is => 'rw', isa => 'Str', default => '/etc/hosts' );
has hostfile => (is => 'ro', isa => 'Str', writer => '_set_hostfile', lazy => 1, builder => 'load_hostfile', init_arg => undef );

sub load_hostfile {
	my ($self, $filename) = @_;

	$filename = $self->hostfile_path unless defined $filename;

	unless (-e $filename)
	{
		Carp::croak("Hostfile must exist.  File not found at $filename");
	}

	$self->_set_hostfile(read_file($filename));
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

no Moose;
__PACKAGE__->meta->make_immutable;
