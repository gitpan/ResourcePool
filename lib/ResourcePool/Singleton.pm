#*********************************************************************
#*** ResourcePool::Singleton.pm
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: Singleton.pm,v 1.10 2002/10/12 17:25:00 mws Exp $
#*********************************************************************

package ResourcePool::Singleton;

use strict;
use vars qw($VERSION);

$VERSION = "0.9910";

BEGIN {
	my $key_hash = {};
	sub new($$) {
		my $proto = shift;
		my $class = ref($proto) || $proto;
		my $key = shift || 'UKN';
		my $self = {};
		
		my $rv = $key_hash->{$class}->{$key};
		if ($rv) {
			return $rv;
		}

		$key_hash->{$class}->{$key} = $self;

		bless($self, $class);
		
		return $self;

	}
}
1;
