#*********************************************************************
#*** ResourcePool::Factory::Net::LDAP
#*** Copyright (c) 2001 by Markus Winand <mws@fatalmind.com>
#*** $Id: LDAP.pm,v 1.6 2001/08/19 09:39:43 mws Exp $
#*********************************************************************

package ResourcePool::Factory::Net::LDAP;
use strict;
use vars qw($VERSION @ISA);
use ResourcePool::Factory;
use ResourcePool::Resource::Net::LDAP;
use Net::LDAP;
use Data::Dumper;

push @ISA, "ResourcePool::Factory";
$VERSION = "0.9903";

sub new($$@) {
        my ($proto) = shift;
        my $class = ref($proto) || $proto;
        my $self;
	my $key;
	my $d = Data::Dumper->new([@_]);
	$d->Indent(0);
	$key = $d->Dump();
	$self = $class->SUPER::new("Net::LDAP".$key);	# parent uses Singelton

	if (! exists($self->{host})) {
        	$self->{host} = shift;
	        $self->{BindOptions} = shift;
		$self->{NewOptions} = shift;
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

	return $self->{host};
}


1;

__END__

=head1 NAME

ResourcePool::Factory::Net::LDAP - A Net::LDAP Factory for ResourcePool

=head1 SYNOPSIS

 use ResourcePool::Factory::Net::LDAP;

 my $factory = ResourcePool::Factory::Net::LDAP->new($hostname, 
				[@NamedBindOptions],
				[@NamedNewOptions]);

=head1 DESCRIPTION

This class is a Factory class for Net::LDAP Resources to be used with the
ResourcePool class.

Please read the ResourcePool::Factory(3pm) manpage about the purpos of such
a factory.

=head2 ResourcePool::Factory::Net::LDAP->new

=over 4

=item $hostname

The hostname of the LDAP server. Please note: The portnumber (if not 389)
has to go to the [@New] option, see below.

=item [@NamedBindOptions]

This is a list of named options which will be passed to the Net::LDAP->bind()
call.

=item [@NamedNewOptions]

This is a list of named options which will be passed to the Net::LDAP->new()
call.

If you have to use a LDAP Server on an non-standard port you have to include
the 'port' parameter here.

=head2 EXAMPLE

To connect to the server ldap.domain.com on port 389 and bind anonymously:

   my $factory = ResourcePool::Factory::Net::LDAP->new(
                     "ldap.domain.com"
   );

To connect to the same server and bind with a dn and password:

   my $factory = ResourcePool::Factory::Net::LDAP->new(
                     "ldap.domain.com",
                     [
                         dn       => "cn=Manager,dc=domain,dc=com",
                         password => "secret" 
                     ]
   );

To connect to the same server but to the port 10000 and bind anonymously:

   my $factory = ResourcePool::Factory::Net::LDAP->new(
                     "ldap.domain.com",
                     [],	# no bind options
                     [port => 10000]
   );

=head1 SEE ALSO

ResourcePool(3pm), ResourcePool::Factory(3pm), ResourcePool::Factory::DBI(3pm)

=head1 AUTHOR

    Copyright (C) 2001 by Markus Winand <mws@fatalmind.com>

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

