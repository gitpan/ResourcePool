#*********************************************************************
#*** ResourcePool::Resource::DBI
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: DBI.pm,v 1.15 2002/07/10 17:27:44 mws Exp $
#*********************************************************************

package ResourcePool::Resource::DBI;

use vars qw($VERSION @ISA);
use strict;
use DBI;
use ResourcePool::Resource;

$VERSION = "0.9906";
push @ISA, "ResourcePool::Resource";

sub new($$$$$) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	my $ds   = shift;
	my $user = shift;
	my $auth = shift;
	my $attr = shift;

	eval {
		$self->{dbh} = DBI->connect($ds, $user, $auth, $attr);
	}; 
	if (! defined $self->{dbh}) {
		warn "ResourcePool::Resource::DBI: Connect to '$ds' failed: $DBI::errstr\n";
		return undef;
	}
	bless($self, $class);

	return $self;
}

sub close($) {
	my ($self) = @_;
	eval {
		$self->{dbh}->disconnect();
	};
}

sub precheck($) {
	my ($self) = @_;	
	my $rc = $self->{dbh}->ping();

	if (!$rc) {
		eval {
			$self->close();
		};
	}
	return $rc;
}

sub postcheck($) {
	my ($self) = @_;

	if (! $self->{dbh}->{AutoCommit}) {
		eval {
			$self->{dbh}->rollback();
		};
	}
	return 1;
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

=head1 SYNOPSIS

 use ResourcePool::Resource::DBI;

 my $resource =  ResourcePool::Resource::DBI->new(
                        $data_source, 
                        $username, 
                        $auth, 
                        \%attr);

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

Always returns true, but does a rollback() on the session 
(if AutoCommit is off).

=head1 SEE ALSO

L<ResourcePool(3pm)>, 
L<ResourcePool::Resource(3pm)>

=head1 AUTHOR

    Copyright (C) 2002 by Markus Winand <mws@fatalmind.com>

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.
