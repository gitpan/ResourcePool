#*********************************************************************
#*** ResourcePool::Factory
#*** Copyright (c) 2001 by Markus Winand <mws@fatalmind.com>
#*** $Id: Factory.pm,v 1.7 2001/08/19 09:39:43 mws Exp $
#*********************************************************************

package ResourcePool::Factory;

use strict;
use vars qw($VERSION @ISA);
use ResourcePool::Singelton;
use ResourcePool::Resource;

push @ISA, "ResourcePool::Singelton";
$VERSION = "0.9903";

sub new($$) {
        my $proto = shift;
        my $class = ref($proto) || $proto;
	my $key = shift;
        my $self;

	$self = $class->SUPER::new("ResourcePool::Factory::".  $key);#Singelton
	if (! exists($self->{Used})) {
		$self->{Used} = 1;
	}

        bless($self, $class);

        return $self;
}

sub create_resource() {
	return ResourcePool::Resource->new();
}

sub info($) {
	my ($self) = @_;
	return $self;	
}

1;

__END__

=head1 NAME

ResourcePool::Factory - A factory to create ResourcePool::Resource objects

=head1 SYNOPSIS

 use ResourcePool::Factory;

 my $factory = ResourcePool->new();

=head1 DESCRIPTION

This package is not indented to be used directly. In fact it is a base class
to derive your own classes to use with the ResourcePool.

This factories are used in conjunction with the ResourcePool class.

The purpose of such factories is to store the relevant data to create a
resource in their private storage. Afterwards a resource can be created 
without any further parameters.

=head2 ResourcePool::Factory->new()

The new method is called to create a new factory.

Usually this method just stores the parameters somewhere, blesses itself and 
returnes the blessed reference.

You must overload this method in order to do something usefull.

=head2 $pool->create_resource()

This method is used to actually create a resource according to the parameters
given to the new() method.

You must overload this method in order to do something usefull.

=head2 $pool->info()

This method is sometimes used to report details about a failed resource.

You must not overload this method.

=head1 SEE ALSO

ResourcePool(3pm), ResourcePool::Resource(3pm), ResourcePool::Factory::DBI(3pm),
ResourcePool::Factory::Net::LDAP(3pm)

=head1 AUTHOR

    Copyright (C) 2001 by Markus Winand <mws@fatalmind.com>

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

