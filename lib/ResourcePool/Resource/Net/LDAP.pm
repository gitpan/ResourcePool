#*********************************************************************
#*** ResourcePool::Resource::Net::LDAP
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: LDAP.pm,v 1.10 2002/07/03 19:25:36 mws Exp $
#*********************************************************************

package ResourcePool::Resource::Net::LDAP;

use vars qw($VERSION @ISA);
use strict;
use Net::LDAP;
use Net::LDAP::Constant qw(:all);
use ResourcePool::Resource;
use Data::Dumper;

$VERSION = "0.9905";
push @ISA, "ResourcePool::Resource";

sub new($$$@) {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self = {};
	$self->{Factory} = shift;
        my $host   = shift;
	$self->{BindOptions} = defined $_[0] ? shift: [];
	my $NewOptions = defined $_[0] ? shift: [];

	$self->{ldaph} = Net::LDAP->new($host, @{$NewOptions});
	if (! defined $self->{ldaph}) {
		swarn("ResourcePool::Resource::Net::LDAP: ".
			"Connect to '%s' failed: $@\n", 
			$self->{Factory}->info());
		return undef;
	}
	
        bless($self, $class);

	return $self->bind();

        return $self;
}

sub close($) {
	my ($self) = @_;
	#$self->{ldaph}->unbind();
}

sub fail_close($) {
	my ($self) = @_;
	swarn("ResourcePool::Resource::Net::LDAP: ".
		"closing failed connection to '%s'.\n",
		$self->{Factory}->info());
}

#sub postcheck($) {
#	my ($self) = @_;	
#	return 1;
#}

sub get_plain_resource($) {
	my ($self) = @_;
	return $self->{ldaph};
}

sub DESTROY($) {
	my ($self) = @_;
	$self->close();
}

sub precheck($) {
	my ($self) = @_;
	return $self->bind();
}


sub bind($) {
	my ($self) = @_;
	my %BindOptions = (@{$self->{BindOptions}});
	my $rc;
	
	if ( defined $BindOptions{dn}) {
		$rc = $self->{ldaph}->bind(@{$self->{BindOptions}});
	} else {
		$rc = $self->{ldaph}->bind();
	}

	if ($rc->code != LDAP_SUCCESS) {
		if (defined $BindOptions{dn}) {
			swarn("ResourcePool::Resource::Net::LDAP: ".
				"Bind as '%s' to '%s' failed: %s\n",
				$BindOptions{dn},
				$self->{Factory}->info(),
				$rc->error());
		} else {
			swarn("ResourcePool::Resource::Net::LDAP: ".
				"anonymous Bind to '%s' failed: %s\n",
				$self->{Factory}->info(),
				$rc->error());
		}
		delete $self->{ldaph};
		return undef;
	}

	return $self;
}


sub swarn($@) {
	my $fmt = shift;
	warn sprintf($fmt, @_);
}
1;

=head1 NAME

ResourcePool::Resource::Net::LDAP - A ResourcePool wrapper for Net::LDAP

=head1 SYNOPSIS

 use ResourcePool::Resource::Net::LDAP;

 my $resource = ResourcePool::Resource::Net::LDAP->new(
                   $factory,
                   $hostname, 
                   [@NamedBindOptions],
                   [@NamedNewOptions]);

=head1 DESCRIPTION

This class is used by the ResourcePool internally to create Net::LDAP 
connections.
It's called by the corresponding ResourcePool::Factory::Net::LDAP object 
which passes the parameters needed to establish the Net::LDAP connection.

The only thing which has to been known by an application developer about this
class is the implementation of the precheck() and postcheck() methods:

=over 4

=item precheck()

Performs a bind(), either anonymous or with dn and password (depends on the
arguments to ResourcePool::Factory::Net::LDAP). 

Returns true on success and false if the bind failed (regardless of the reason).

=item postcheck()

Does not implement any postcheck().

=head1 SEE ALSO

ResourcePool(3pm), ResourcePool::Resource(3pm)

=head1 AUTHOR

    Copyright (C) 2002 by Markus Winand <mws@fatalmind.com>

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

