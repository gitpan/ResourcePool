#*********************************************************************
#*** ResourcePool::LoadBalancer::RoundRobin
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: RoundRobin.pm,v 1.3 2002/10/12 17:25:04 mws Exp $
#*********************************************************************

package ResourcePool::LoadBalancer::RoundRobin;

use vars qw($VERSION @ISA);
use ResourcePool::LoadBalancer;

$VERSION = "0.9910";
push @ISA, "ResourcePool::LoadBalancer";

sub get_once($) {
	my ($self) = @_;
	my $rec;
	my $r_pool;

	$r_pool = $self->{PoolArray}->[$self->{Next}++];
	if ($self->{Next} >= scalar(@{$self->{PoolArray}})) {
		$self->{Next} = 0;
	}
	if (! $self->chk_suspend($r_pool)) {
		$rec = $r_pool->{pool}->get();
		if (! defined $rec) {
			$self->suspend($r_pool);
		}
	}
	if ( $self->chk_suspend($r_pool)) {
		undef $rec;
		undef $r_pool;
	}
	return ($rec, $r_pool);
}

1;