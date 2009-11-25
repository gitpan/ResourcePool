#*********************************************************************
#*** ResourcePool::Singleton.pm
#*** Copyright (c) 2002,2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: Singleton.pm,v 1.17 2009-11-25 14:40:22 mws Exp $
#*********************************************************************

package ResourcePool::Singleton;

use strict;
use vars qw($VERSION);

$VERSION = "1.0106";

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

	sub is_created($$) {
		my $proto = shift;
		my $class = ref($proto) || $proto;
		my $key = shift || 'UKN';

		return defined $key_hash->{$class}->{$key};
	}

}
1;
