#*********************************************************************
#*** ResourcePool::Factory
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: Factory.pm,v 1.18 2002/09/02 10:22:58 mws Exp $
#*********************************************************************

package ResourcePool::Factory;

use strict;
use vars qw($VERSION @ISA);
use ResourcePool::Singleton;
use ResourcePool::Resource;

push @ISA, "ResourcePool::Singleton";
$VERSION = "0.9908";

sub new($$) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $key = shift;
	my $self;

	$self = $class->SUPER::new("ResourcePool::Factory::".  $key);#Singleton
	if (! exists($self->{Used})) {
		$self->{Used} = 0;
	}

	bless($self, $class);

	return $self;
}

sub create_resource($) {
	my ($self) = @_;
	++$self->{Used};
	return ResourcePool::Resource->new();
}

sub info($) {
	my ($self) = @_;
	return $self;	
}

sub _my_very_private_and_secret_test_hook($) {
	my ($self) = @_;
	return $self->{Used};
}

1;
