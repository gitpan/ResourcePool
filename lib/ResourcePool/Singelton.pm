#*********************************************************************
#*** ResourcePool::Singelton.pm
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: Singelton.pm,v 1.8 2002/01/20 16:32:47 mws Exp $
#*********************************************************************

package ResourcePool::Singelton;

use strict;
use vars qw($VERSION);

$VERSION = "0.9904";

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
 use ResourcePool::Singelton;
 use Data::Dumper;
 
 push @ISA, "ResourcePool::Singelton";
 
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

The Singelton class, or clasess derived from this class, can be instantiated 
only once. If you call the constructor of this class the first time, it will
perform an normal object construction and return a reference to a blessed
value. But it will also store this reference in a global hash.

On further calls of this constructor the Singelton class will just return the
stored reference instead of creating a new one.

This is very useful if the construction of an object is very expansive but it
is required to be constructed at different places in your program. A special
application for this feature is a Apache/mod_perl environment.

The Singelton class can not check if the stored object references are still 
valid, therfore it might return references to objects which have already 
been destroyed. If you need a persistant object which gets recreated on 
failure you should consider to use the ResourcePool and/or the LoadBalancer
modules.

=head2 Singelton->new($$)

The construcotr takes one argument which is a key to the object wich will be 
created. You have to build a key which is unique for your needs. In most
cases it's most appropriate to use the Data::Dumper like shown above to
construct such a key.

=head1 AUTHOR

    Copyright (C) 2002 by Markus Winand <mws@fatalmind.com>

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

