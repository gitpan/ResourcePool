#*********************************************************************
#*** ResourcePool::Singleton.pm
#*** Copyright (c) 2002,2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: Singleton.pm,v 1.14.2.1 2003/03/27 20:35:58 mws Exp $
#*********************************************************************

package ResourcePool::Singleton;

use strict;
use vars qw($VERSION);

$VERSION = "1.0102";

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
