#*********************************************************************
#*** ResourcePool::LoadBalancer::LeastUsage
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: LeastUsage.pm,v 1.2 2002/10/12 17:25:04 mws Exp $
#*********************************************************************

package ResourcePool::LoadBalancer::LeastUsage;

use vars qw($VERSION @ISA);
use ResourcePool::LoadBalancer;

$VERSION = "0.9910";
push @ISA, "ResourcePool::LoadBalancer";

sub get_once($) {
	my ($self) = @_;
	my ($rec, $pool);
	my ($least_val, $least_r_pool);
	my $r_pool;
	my $val;

	foreach $r_pool (@{$self->{PoolArray}}) {
		if ($self->chk_suspend($r_pool)) {
			next; # skip suspended
		}
		if (! defined $least_val) {
			$least_val = $r_pool->{pool}->get_stat_used() * 
					$r_pool->{Weight};
			$least_r_pool = $r_pool;
		} else {
			$val = $r_pool->{pool}->get_stat_used() * 
					$r_pool->{Weight};
			if ($val < $least_val) {
				$least_val = $val;
				$least_r_pool = $r_pool;
			} elsif ($val == $least_val) {
				if ($r_pool->{UsageCount} < 
						$least_r_pool->{UsageCount}) {
					$least_val = $val;
					$least_r_pool = $r_pool;
				}
			}
		}
	}	
	if (defined $least_r_pool) {
		$rec = $least_r_pool->{pool}->get();
		if (! defined $rec) {
			$self->suspend($least_r_pool);
			undef $rec;
			undef $r_pool;
		} else {
			$least_r_pool->{UsageCount} += $least_r_pool->{Weight};
		}
	}
	return ($rec, $least_r_pool);		
}

1;