#*********************************************************************
#*** ResourcePool::Singelton.pm
#*** Copyright (c) 2001 by Markus Winand <mws@fatalmind.com>
#*** $Id: Singelton.pm,v 1.5 2001/10/15 18:51:51 mws Exp $
#*********************************************************************

package ResourcePool::Singelton;

use strict;
use vars qw($VERSION);

$VERSION = "0.9903";

BEGIN {
	my $key_hash = {};
	sub new($$) {
		my $proto = shift;
		my $class = ref($proto) || $proto;
		my $key = shift || 'UKN';
		my $self = {};
		
		if (exists($key_hash->{$key})) {
			return $key_hash->{$key};
		}

		$key_hash->{$key} = $self;

		bless($self, $class);
		
		return $self;

	}
}
1;

__END__

=head1 NAME

Singelton - A class which can instantiated only once.

=head1 SYNOPSIS

 package Testme;
 use Singelton;
 use Data::Dumper;
 
 push @ISA, "Singelton";
 
 sub new($@) {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $d = Data::Dumper->new([@_]);
    $d->Indent(0);
    my $key = $d->Dump();
    my $self;
    
    $self = $class->SUPER::new("Testme". $key);
    if (!exists($self->{CNT})) {
       $self->{CNT} = $_[0];
       bless($self, $class);
    }
    return $self;
 }	
 
 sub next($) {
     my ($self) = @_;
     return $self->{CNT}++;
 }
 

=head1 DESCRIPTION

The Singelton class may be used to impelment classes which can be 
instantiated only once. On the first call try to instantiate such a class 
the class gets constructed normally. At the second time the same object which
was constructed first will be returned.

This can be usefull if a program needs access to a global object which gets
constructed only once. It is typically used for DB connections of any kind
(including LDAP) or raw sockets or a Resource manager like ResourcePool.

In most cases it is recommended to use the ResourcePool since this can handle
Connection losses and failovers.

=head2 Singelton->new($$)

The construcotr takes one argument which is a key to the object wich will be 
created. You have to build a key which is uniq for your needs. In most
cases it's most appropriate to use the Data::Dumper like shown above to
construct such a key.

=head1 AUTHOR

    Copyright (C) 2001 by Markus Winand <mws@fatalmind.com>

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

