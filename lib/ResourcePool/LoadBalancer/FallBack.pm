#*********************************************************************
#*** ResourcePool::LoadBalancer::FallBack
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: FallBack.pm,v 1.3.2.1 2002/12/22 11:58:55 mws Exp $
#*********************************************************************

package ResourcePool::LoadBalancer::FallBack;

use vars qw($VERSION @ISA);
use ResourcePool::LoadBalancer;

$VERSION = "1.0000";
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
