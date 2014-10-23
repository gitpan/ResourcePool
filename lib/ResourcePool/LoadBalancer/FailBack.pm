#*********************************************************************
#*** ResourcePool::LoadBalancer::FailBack
#*** Copyright (c) 2002-2005 by Markus Winand <mws@fatalmind.com>
#*** $Id: FailBack.pm,v 1.1.2.3 2005/01/05 19:43:36 mws Exp $
#*********************************************************************

package ResourcePool::LoadBalancer::FailBack;

use vars qw($VERSION @ISA);
use ResourcePool::LoadBalancer;

$VERSION = "1.0104";
push @ISA, "ResourcePool::LoadBalancer";

sub get_once($) {
	my ($self) = @_;
	my ($rec, $r_pool);
	my $i = 0;

	do {	# get first not suspended pool 
		$r_pool = $self->{PoolArray}->[$i++];
	} while (defined $r_pool && $self->chk_suspend($r_pool)) ;

	if (defined $r_pool) {	 #
		$rec = $r_pool->{pool}->get();
		if (! defined $rec) {
			$self->suspend($r_pool);
		}

		if (defined $self->{LastUsedPool} && $r_pool != $self->{LastUsedPool}) {
			$self->{LastUsedPool}->{pool}->downsize();
		}
		$self->{LastUsedPool} = $r_pool;
	}
	if (! defined $rec) {
		undef $r_pool;
	}
	return ($rec, $r_pool);
}

sub free_policy($$) {
	my ($self, $r_pool) = @_;

	if ($r_pool != $self->{LastUsedPool}) {
		$self->{LastUsedPool}->{pool}->downsize();
	}
	return 1;
}


1;
