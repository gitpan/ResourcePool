#*********************************************************************
#*** ResourcePool::Resource::DBI
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: DBI.pm,v 1.8 2002/01/20 16:32:47 mws Exp $
#*********************************************************************

package ResourcePool::Resource::DBI;

use vars qw($VERSION @ISA);
use strict;
use DBI;
use ResourcePool::Resource;

$VERSION = "0.9904";
push @ISA, "ResourcePool::Resource";

sub new($$$$$) {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self = {};
        my $ds   = shift;
        my $user = shift;
        my $auth = shift;
        my $attr = shift;

	$self->{dbh} = DBI->connect($ds, $user, $auth, $attr);
	if (! defined $self->{dbh}) {
		warn "ResourcePool::Resource::DBI: Connect to '$ds' failed: $DBI::errstr\n";
		return undef;
	}
        bless($self, $class);

        return $self;
}

sub close($) {
	my ($self) = @_;
	$self->{dbh}->disconnect();
}

sub precheck($) {
	my ($self) = @_;	
	my $rc = $self->{dbh}->ping();

	if (!$rc) {
		$self->close();
	}
	return $rc;
}

sub get_plain_resource($) {
	my ($self) = @_;
	return $self->{dbh};
}

sub DESTROY($) {
	my ($self) = @_;
	$self->close();
}

1;


__END__

=head1 NAME

ResourcePool::Resource::DBI - A ResourcePool wrapper for DBI

=head1 DESCRIPTION

This class is used by the ResourcePool internally to create DBI connections.
Its called by the corresponding ResourcePool::Factory::DBI object which passes
the parameters needed to establish the DBI connection.

The only thing which has to been known by an application developer about this
class is the implementation of the precheck() and postcheck() methods:

=over 4

=item precheck()

Performs a $dbh->ping().

Returns true on success and false on fail.

=item postcheck()

Does not implement any postcheck().

=head1 SEE ALSO

ResourcePool(3pm), ResourcePool::Resource(3pm)

=head1 AUTHOR

    Copyright (C) 2002 by Markus Winand <mws@fatalmind.com>

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.
