#*********************************************************************
#*** ResourcePool::Singleton.pm
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: Singleton.pm,v 1.8 2002/10/06 13:43:21 mws Exp $
#*********************************************************************

package ResourcePool::Singleton;

use strict;
use vars qw($VERSION);

$VERSION = "0.9909";

BEGIN {
	my $key_hash = {};
	sub new($$) {
		my $proto = shift;
		my $class = ref($proto) || $proto;
		my $key = shift || 'UKN';
		my $self = {};
		
		if (exists($key_hash->{$class}) && 
			exists($key_hash->{$class}->{$key})) 
		{
			return $key_hash->{$class}->{$key};
		}

		$key_hash->{$class}->{$key} = $self;

		bless($self, $class);
		
		return $self;

	}
}
1;
