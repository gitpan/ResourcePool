#*********************************************************************
#*** ResourcePool::Factory::DBI
#*** Copyright (c) 2001 by Markus Winand <mws@fatalmind.com>
#*** $Id: DBI.pm,v 1.6 2001/10/10 20:23:56 mws Exp $
#*********************************************************************

package ResourcePool::Factory::DBI;

use vars qw($VERSION @ISA);
use strict;
use ResourcePool::Resource::DBI;
use ResourcePool::Factory;
use DBI;
use Data::Dumper;

$VERSION = "0.9903";
push @ISA, "ResourcePool::Factory";

sub new($$$$$) {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self;
	my $d = Data::Dumper->new([@_]);
	$d->Indent(0);
	my $key = $d->Dump();
	$self = $class->SUPER::new("DBI". $key); # parant uses Singelton

	if (! exists($self->{DS})) {
	        $self->{DS} = shift;
       		$self->{user} = shift;
	        $self->{auth} = shift;
	        $self->{attr} = shift;
	}

        bless($self, $class);

        return $self;
}

sub create_resource($) {
	my ($self) = @_;
	return ResourcePool::Resource::DBI->new(	
				$self->{DS}
			,	$self->{user}
			,	$self->{auth}
			,	$self->{attr}
	);
}

1;

__END__

=head1 NAME

ResourcePool::Factory::DBI - A DBI Factory for ResourcePool

=head1 SYNOPSIS

 use ResourcePool::Factory::DBI;

 my $factory =  ResourcePool::Factory::DBI->new($data_source, 
						$username, 
						$auth, 
						\%attr);

=head1 DESCRIPTION

This class is a Factory class for DBI Resources to be used with the 
ResourcePool class.

Please read the ResourcePool::Factory(3pm) manpage about the purpos of such
a factory.

=head2 ResourcePool::Factory::DBI->new

Takes the same arguements as the connect method of the DBI perl module.

=head1 SEE ALSO

ResourcePool(3pm), ResourcePool::Factory(3pm), ResourcePool::Factory::Net::LDAP(3pm)

=head1 AUTHOR

    Copyright (C) 2001 by Markus Winand <mws@fatalmind.com>

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

