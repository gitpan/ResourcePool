#*********************************************************************
#*** ResourcePool::Resource
#*** Copyright (c) 2001 by Markus Winand <mws@fatalmind.com>
#*** $Id: Resource.pm,v 1.7 2001/10/07 18:32:55 mws Exp $
#*********************************************************************

package ResourcePool::Resource;

use strict;
use vars qw($VERSION);

$VERSION = "0.9903";

sub new($) {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self = {};
	$self->{PlainResource} = {};

        bless($self, $class);

        return $self;
}

sub close($) {
	my ($self) = @_;
	return undef;
}

sub fail_close($) {
	my ($self) = @_;
	warn "ResourcePool::Resource: closing failed Resource\n";
	return undef;
}

sub precheck($) {
	my ($self) = @_;
	return 1;
}

sub postcheck($) {
	my ($self) = @_;
	return 1;
}

sub get_plain_resource($) {
	my ($self) = @_;
	return $self->{PlainResource};
}

1;

__END__

=head1 NAME
 
ResourcePool::Resource - A wraper class for a resource

=head1 DESCRIPTION

This type of classes is used by the ResourcePool internaly.
It's thougt to be an abstract base class for further resources which will be
used with the ResourcePool.

This classes gets constructed by a Factory like ResourcePool::Factory.
The factory knows about the actual parameters to pass to the Resource. So in fact a
Factory doens't create the resource like DBI , it creates a wrapper Resource for it
which also supports some test functionality.

Every from ResourcePool::Resource derived class must 
overload this member functions:

=head2 $self->close()

Closes a connection gracefully.

=head2 $self->fail_close()

Closes a failed connection and ignores error (since this connection is known 
as bad)

=head2 $self->get_plain_resource

Returns the nacked resource which can be used by the client. This an the DBI or
Net::LDAP handle for example.


Additonally a ResourcePool::Resource derived class should overload at least
one of the check methods:

=head2 $self->precheck()

Checks a connection. This method is called by the get() method of the 
ResourcePool before it returns a connection. 
The default implementation always returns true.

=head2 $self->postcheck()

Checks a connection. This method is called by the free() method of the
ResourcePool to check if a connection is still valid. 
The default implementation always returns true.
 
=head1 SEE ALSO

ResourcePool(3pm), 
ResourcePool::Resource::DBI(3pm), ResourcePool::Resource::Net::LDAP(3pm)

=head1 AUTHOR

    Copyright (C) 2001 by Markus Winand <mws@fatalmind.com>

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

