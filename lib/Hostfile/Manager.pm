package Hostfile::Manager;

use strict;
use warnings;
use Moose;
use File::Find;
use File::Slurp;
use File::Basename qw/dirname/;

our $VERSION = '0.4';

has path_prefix => (
    is      => 'rw',
    isa     => 'Str',
    default => '/etc/hostfiles/',
);

has hostfile_path => (
    is      => 'rw',
    isa     => 'Str',
    default => '/etc/hosts',
);

has hostfile => (
    is       => 'ro',
    isa      => 'Str',
    writer   => '_set_hostfile',
    lazy     => 1,
    builder  => 'load_hostfile',
    init_arg => undef,
);

has blocks => (
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { {} },
    init_arg => undef,
);

has fragments => (
    is      => 'ro',
    isa     => 'HashRef[Str]',
    traits  => ['Hash'],
    lazy    => 1,
    builder => '_load_fragments',
    handles => {
        fragment_list => 'keys',
        get_fragment  => 'get',
    },
    init_arg => undef,
);

sub load_hostfile {
    my ( $self, $filename ) = @_;

    $filename = $self->hostfile_path unless defined $filename;

    unless ( -e $filename ) {
        Carp::croak("Hostfile must exist.  File not found at $filename");
    }

    my $file = read_file($filename);
    $self->_set_hostfile($file);
}

sub write_hostfile {
    my $self = shift;

    my $filename = $self->hostfile_path;

    unless ( ( !-e $filename && -w dirname($filename) ) || -w $filename ) {
        Carp::croak("Unable to write hostfile to $filename");
    }

    write_file( $filename, $self->hostfile );
}

sub fragment_enabled {
    my ( $self, $fragment_name ) = @_;

    $self->hostfile =~ $self->block($fragment_name);
}

sub enable_fragment {
    my ( $self, $fragment_name ) = @_;

    my $fragment = $self->get_fragment($fragment_name) or return;

    $self->disable_fragment($fragment_name)
      if $self->fragment_enabled($fragment_name);
    $self->_set_hostfile( $self->hostfile
          . "# BEGIN: $fragment_name\n$fragment# END: $fragment_name\n" );
}

sub disable_fragment {
    my ( $self, $fragment_name ) = @_;

    my $hostfile = $self->hostfile;
    $hostfile =~ s/@{[$self->block($fragment_name)]}//g;

    $self->_set_hostfile($hostfile);
}

sub toggle_fragment {
    my ( $self, $fragment_name ) = @_;

    if ( $self->fragment_enabled($fragment_name) ) {
        $self->disable_fragment($fragment_name);
    }
    else {
        $self->enable_fragment($fragment_name);
    }
}

sub block {
    my ( $self, $block_name ) = @_;

    $self->blocks->{$block_name} ||=
qr/(?:#+[\r\n])?#+\s*BEGIN: $block_name[\r\n](.*)#+\s*END: $block_name[\r\n]/ms;
    return $self->blocks->{$block_name};
}

sub _load_fragments {
    my $self      = shift;
    my $fragments = {};
    my $prefix    = $self->path_prefix;

    find(
        {
            wanted => sub {
                return if -d $_;
                $_ =~ s{^$prefix}{};
                $fragments->{$_} = $self->_load_fragment($_);
            },
            no_chdir => 1
        },
        $prefix
    );

    $fragments;
}

sub _load_fragment {
    my ( $self, $fragment_name ) = @_;

    my $filename = $self->path_prefix . $fragment_name;

    unless ( -e $filename ) {
        Carp::carp("Fragment not found at $filename");
        return;
    }

    read_file($filename);
}

sub fragment_status_flag {
    my ( $self, $fragment_name ) = @_;
    my $fragment_contents = $self->get_fragment($fragment_name);

    my $found = $self->hostfile =~ /@{[$self->block($fragment_name)]}/g;
    return $found ? ( $1 eq $fragment_contents ? "+" : "*" ) : " ";
}

no Moose;
__PACKAGE__->meta->make_immutable;
