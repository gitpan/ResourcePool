#*********************************************************************
#*** ResourcePool::Resource
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: Resource.pm,v 1.15.2.1 2002/08/30 16:25:11 mws Exp $
#*********************************************************************

package ResourcePool::Resource;

use strict;
use vars qw($VERSION);

$VERSION = "0.9907";

sub new($@) {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self = {};
	$self->{PlainResource} = {shift => $self};
	$self->{VALID} = 1;

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
	return $self->{VALID};
}

sub postcheck($) {
	my ($self) = @_;
	return $self->{VALID};
}

sub get_plain_resource($) {
	my ($self) = @_;
	return $self->{PlainResource};
}

sub _my_very_private_and_secret_test_hook($$) {
	my ($self, $valid) = $_;
	$self->{VALID} = $valid;
}

1;

__END__

=head1 NAME

ResourcePool::Resource - A wrapper class for a resource

=head1 SYNOPSIS

 use ResourcePool::Resource;

 my $resource = ResourcePool::Resource->new();

=head1 DESCRIPTION

This type of classes is used by the ResourcePool internaly.
It's thougt to be an abstract base class for further resources which will be
used with the ResourcePool.

This classes gets constructed by a Factory like ResourcePool::Factory.
The factory knows about the actual parameters to pass to the Resource. 
So in fact a Factory doens't create the resource like DBI, 
it creates a wrapper Resource for it which also supports some test 
functionality.

Every class which is derived from  ResourcePool::Resource must 
overload this member functions:

=head2 S<$self-E<gt>close>

Closes a connection gracefully.

=head2 S<$self-E<gt>fail_close>

Closes a failed connection and ignores error (since this connection is known 
as bad)

=head2 S<$self-E<gt>get_plain_resource>

Returns the nacked resource which can be used by the client. This an the DBI or
Net::LDAP handle for example.


Additonally a ResourcePool::Resource derived class should overload at least
one of the check methods:

=head2 S<$self-E<gt>precheck>

Checks a connection. This method is called by the get() method of the 
ResourcePool before it returns a connection. 
The default implementation always returns true.

=head2 S<$self-E<gt>postcheck>

Checks a connection. This method is called by the free() method of the
ResourcePool to check if a connection is still valid. 
The default implementation always returns true.
 
=head1 SEE ALSO

L<ResourcePool(3pm)>, 
L<ResourcePool::Resource::DBI(3pm)>, 
L<ResourcePool::Resource::Net::LDAP(3pm)>

=head1 AUTHOR

    Copyright (C) 2002 by Markus Winand <mws@fatalmind.com>

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

