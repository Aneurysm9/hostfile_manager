package Hostfile::Manager;

use strict;
use warnings;
use Moose;
use File::Slurp;
use File::Find;

our $VERSION = '0.3';

has path_prefix => ( is => 'rw', isa => 'Str', default => '/etc/hostfiles/' );
has hostfile_path => ( is => 'rw', isa => 'Str', default => '/etc/hosts' );
has hostfile => (is => 'ro', isa => 'Str', writer => '_set_hostfile' );

sub load_hostfile {
	my ($self, $filename) = @_;

	$filename = $self->hostfile_path unless defined $filename;

	$self->_set_hostfile(read_file($filename));
}

1;
