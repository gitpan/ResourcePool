#*********************************************************************
#*** ResourcePool::Factory
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: Factory.pm,v 1.24 2002/10/12 17:25:00 mws Exp $
#*********************************************************************

package ResourcePool::Factory;

use strict;
use vars qw($VERSION @ISA);
use ResourcePool::Singleton;
use ResourcePool::Resource;
use Data::Dumper;
use Storable;

push @ISA, "ResourcePool::Singleton";
$VERSION = "0.9910";

####
# Some notes about the singleton behavior of this class.
# 1. the constructor does not return a singleton reference!
# 2. there is a seperate function called singelton() which will return a
#    singleton reference
# this change was introduces with ResourcePool 0.9910 to allow more flexible
# factories (e.g. factories which do not require all parameters to their 
# constructor) an example of such an factory is the Net::LDAP factory.


sub new($$) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $key = shift;
	my $self = {};
	$self->{key} = $key;
	$self->{VALID} = 1;

	$self->{singleton}->{'_ResourcePool::Factory::key'} = $key;

	bless($self, $class);

	return $self;
}

sub create_resource($) {
	my ($self) = @_;
	++$self->{Used};
	if ($self->{VALID}) {
		return ResourcePool::Resource->new($self->{key});
	} else {
		return undef;
	}
}

sub info($) {
	my ($self) = @_;
	return $self->{key};	
}

sub singleton($) {
        my ($self) = @_;
        my $singleton = $self->SUPER::new($self->mk_singleton_key());
                                                # parent uses Singleton
        if (!$singleton->{initialized}) {
                %{$singleton} = %{$self};
                $singleton->{initialized} = 1;
        }
        return $singleton;
}

sub mk_singleton_key($) {
#	my $self = shift @_;
#        my ($self) = @_;

        my $d = Data::Dumper->new([$_[0]]);
        $d->Indent(0);
        $d->Terse(1);
        return $d->Dump();
}


sub _my_very_private_and_secret_test_hook($) {
	my ($not_self) = @_;
	my $self = $not_self->singleton();	
	return $self->{Used};
}

sub _my_very_private_and_secret_test_hook2($$) {
	my ($not_self, $mode) = @_;
	my $self = $not_self->singleton();	
	$self->{VALID} = $mode;
}

1;
