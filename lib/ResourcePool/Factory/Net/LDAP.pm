#*********************************************************************
#*** ResourcePool::Factory::Net::LDAP
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: LDAP.pm,v 1.17 2002/09/28 10:30:28 mws Exp $
#*********************************************************************

package ResourcePool::Factory::Net::LDAP;
use strict;
use vars qw($VERSION @ISA);
use ResourcePool::Factory;
use ResourcePool::Resource::Net::LDAP;
use Data::Dumper;

push @ISA, "ResourcePool::Factory";
$VERSION = "0.9908";

sub new($@) {
        my ($proto) = shift;
        my $class = ref($proto) || $proto;
	my $key;
	my $d = Data::Dumper->new([@_]);
	$d->Indent(0);
	$key = $d->Dump();
	my $self = $class->SUPER::new("Net::LDAP".$key);# parent uses Singleton

	if (! exists($self->{host})) {
        	$self->{host} = shift;
		if (defined $_[0] && ref($_[0]) ne "ARRAY") {
			# new syntax, not finished yet, probable in next release
		        $self->{BindOptions} = [];
			$self->{NewOptions} = [@_];
		} else {
			# old syntax, compatiblity...
		        $self->{BindOptions} = defined $_[0]?shift: [];
			$self->{NewOptions} = defined $_[0]?shift: [];
		}
	}
	
        bless($self, $class);

        return $self;
}

sub create_resource($) {
	my ($self) = @_;
	return ResourcePool::Resource::Net::LDAP->new($self 	
			,	$self->{host}
			,	$self->{BindOptions}
			,	$self->{NewOptions}
	);
}

sub info($) {
	my ($self) = @_;
	my $dn;

	if (scalar(@{$self->{BindOptions}}) % 2 == 0) {
		# even numer -> old Net::LDAP->bind syntax
		my %h = @{$self->{BindOptions}};
		$dn = $h{dn};
	} else {
		# odd numer -> new Net::LDAP->bind syntax
		$dn = $self->{BindOptions}->[0];	
	}
	# if dn is still undef -> anonymous bind
	return (defined $dn? $dn . "@" : "" ) . $self->{host};
}


1;
