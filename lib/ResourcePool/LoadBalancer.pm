#*********************************************************************
#*** ResourcePool::LoadBalancer
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: LoadBalancer.pm,v 1.22 2002/10/06 13:43:21 mws Exp $
#*********************************************************************

######
# TODO
#
# -> statistics function
# -> DEBUG

package ResourcePool::LoadBalancer;

use strict;
use vars qw($VERSION @ISA);
use ResourcePool::Singleton;

push @ISA, "ResourcePool::Singleton";
$VERSION = "0.9909";

sub new($$@) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $key = shift;
	my $self;

	$self = $class->SUPER::new("LoadBalancer". $key); # Singleton

	if (! exists($self->{Policy})) {
		$self->{key} = $key;
		$self->{PoolArray} = (); # empty pool list
		$self->{PoolHash} = (); # empty pool hash
		$self->{UsedPool} = (); # mapping from plain_resource to
					# rich pool
		$self->{Next} = 0;
		my %options = (
			Policy => "LeastUsage",
			MaxTry => 6,
			# RoundRobin, LeastUsage, FallBack
			SleepOnFail => [0,1,2,4,8]
		);

		if (scalar(@_) == 1) {
			%options = ((%options), %{$_[0]});
		} elsif (scalar(@_) > 1) {
			%options = ((%options), @_);
		}

		$options{Policy} = uc($options{Policy});
		if ($options{Policy} ne "LEASTUSAGE" && 
			$options{Policy} ne "ROUNDROBIN" &&
			$options{Policy} ne "FALLBACK") {
				$options{Policy} = "LEASTUSAGE";
		}

		if (ref($options{SleepOnFail})) {
			push (@{$options{SleepOnFail}},
				($options{SleepOnFail}->[-1]) x
				($options{MaxTry} - 1 - scalar(@{$options{SleepOnFail}})));
		} else {
			# convinience if you want set SleepOnFail to a scalar
			$options{SleepOnFail}
				= [($options{SleepOnFail}) x ($options{MaxTry} - 1)];
		}
		# truncate list if it is too long
		$#{@{$options{SleepOnFail}}} = $options{MaxTry} - 2;


		$self->{Policy} = $options{Policy};
		$self->{MaxTry} = $options{MaxTry};
		$self->{StatSuspend} = 0;
		$self->{StatSuspendAll} = 0;
		$self->{SleepOnFail} = [reverse @{$options{SleepOnFail}}];
	}

	bless($self, $class);
	return $self;
}

sub add_pool($$@) {
	my $self = shift;
	my $pool = shift;
	my %rich_pool = (
		pool => $pool,
		BadCount => 0,
		SuspendTrigger	=> 1,
		SuspendTimeout	=> 5,
		Suspended       => 0,
		Weight		=> 100,
		@_,
		UsageCount	=> 0,
		StatSuspend => 0,
		StatSuspendTime => 0	
	);
	if (! exists $self->{PoolHash}->{$pool}) {
		push @{$self->{PoolArray}}, \%rich_pool;
		$self->{PoolHash}->{$pool} = \%rich_pool;
	}
}


sub get($) {
	my ($self) = @_;
	my $rec;
	my $maxtry = $self->{MaxTry} - 1;
	my $trylength;
	my $r_pool;

	do {
		$trylength = scalar(@{$self->{PoolArray}}) - $self->{StatSuspend};
		do {
			if ($self->{Policy} eq "ROUNDROBIN") {
				($rec, $r_pool) = $self->get_next();
			} elsif ($self->{Policy} eq "LEASTUSAGE") {
				($rec, $r_pool) = $self->get_least();
			} elsif ($self->{Policy} eq "FALLBACK") {
				($rec, $r_pool) = $self->get_fallback();
			}
		} while (! defined $rec && ($trylength-- > 0));
	} while (! defined $rec && ($maxtry-- > 0) && ($self->sleepit($maxtry)));

	if (defined $rec) {
		$self->{UsedPool}->{$rec} = $r_pool;
	}
	return $rec;
}

# RoundRobin implementation
sub get_next($) {
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

# LeastUsage implementation
sub get_least($) {
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

# FallBack implementation
sub get_fallback($) {
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

		if (defined $self->{LastUsedPool} && $r_pool ne $self->{LastUsedPool}) {
			$self->{LastUsedPool}->{pool}->downsize();
		}
		$self->{LastUsedPool} = $r_pool;
	}
	if (! defined $rec) {
		undef $r_pool;
	}
	return ($rec, $r_pool);
}

sub free($$) {
	my ($self, $rec) = @_;
	my $r_pool = $self->{UsedPool}->{$rec};	

	if (defined $r_pool) {
		$r_pool->{pool}->free($rec);
		if ($self->chk_suspend_no_recover($r_pool)) {
			$r_pool->{pool}->downsize();
		}
		if ($self->{Policy} eq "FALLBACK") {
			if ($r_pool ne $self->{LastUsedPool}) {
				$self->{LastUsedPool}->{pool}->downsize();
			}
		}
		undef $self->{UsedPool}->{$rec};
		return 1;
	} else {
		return 0;
	}
}

sub fail($$) {
	my ($self, $rec) = @_;
	my $r_pool = $self->{UsedPool}->{$rec};

	if (defined $r_pool) {
	 	$r_pool->{pool}->fail($rec);	
		undef $self->{UsedPool}->{$rec};
		if (! $self->chk_suspend($r_pool)) {
			$self->suspend($r_pool);
		}
		return 1;
	} else {
		return 0;
	}
}

sub downsize($) {
	my ($self) = @_;
	my $r_pool;

	foreach $r_pool (@{$self->{PoolArray}}) {
		$r_pool->{pool}->downsize();
	}
}

sub info($) {
	my ($self) = @_;

	return $self->{key};
}

sub get_stat_used($) {
	my ($self) = @_;
	my $r_pool;
	my $used = 0;

	foreach $r_pool (@{$self->{PoolArray}}) {
		$used += $r_pool->{pool}->get_stat_used();
	}	
	return $used;
}

sub get_stat_free($) {
	my ($self) = @_;
	my $r_pool;
	my $free = 0;

	foreach $r_pool (@{$self->{PoolArray}}) {
		$free += $r_pool->{pool}->get_stat_free();
	}	
	return $free;
}
###
# private

sub suspend($$) {
	my ($self, $r_pool) = @_;
#	my $r_pool = $self->{PoolHash}->{$pool};

	swarn("LoadBalancer(%s): Suspending pool to '%s' for %s seconds\n",
		$self->{key},
		$r_pool->{pool}->info(),
		$r_pool->{SuspendTimeout});
	$r_pool->{Suspended} = time + $r_pool->{SuspendTimeout};
	$r_pool->{pool}->downsize();
	$r_pool->{StatSuspend}++;
	$self->{StatSuspend}++;
	$self->{StatSuspendAll}++;
}

sub chk_suspend($$) {
	my ($self, $r_pool) = @_;
#	my $r_pool = $self->{PoolHash}->{$pool};

	if ($self->chk_suspend_no_recover($r_pool)) {
		if ($r_pool->{Suspended} <= time()) {
			$self->{StatSuspend}--;
			$r_pool->{StatSuspendTime} += $r_pool->{SuspendTimeout};
			$r_pool->{StatSuspendTime} += time() - $r_pool->{Suspended};

			$r_pool->{UsageCount} = $self->get_avg_usagecount();
			$r_pool->{Suspended} = 0;
			swarn("LoadBalancer(%s): Recovering pool to '%s'\n",
				$self->{key},
				$r_pool->{pool}->info());
		}
	}
	return $self->chk_suspend_no_recover($r_pool);
}

sub chk_suspend_no_recover($$) {
	my ($self, $r_pool) = @_;

	return $r_pool->{Suspended} > 0;
}

sub get_avg_usagecount($) {
	my ($self) = @_;
	my $r_pool;
	my $usage_sum = 0;
	my $cnt = 0;

	foreach $r_pool (@{$self->{PoolArray}}) {
		if (! $self->chk_suspend_no_recover($r_pool)) {
			$usage_sum += $r_pool->{UsageCount};
			$cnt++;
		}
	}
	if ($cnt > 0) {
		return $usage_sum / $cnt;
	} else {
		return 0;
	}
}

sub sleepit($$) {
	my ($self, $try) = @_;
	my ($r_pool);

	if ($self->{SleepOnFail}->[$try] > 0) {
		swarn("ResourcePool::LoadBalancer> sleeping %s seconds...\n", 
			$self->{SleepOnFail}->[$try]);
		sleep($self->{SleepOnFail}->[$try]);
	}

	foreach $r_pool (@{$self->{PoolArray}}) {
		$self->chk_suspend($r_pool);
	}
	return 1;
}

sub swarn($@) {
	my $fmt = shift;
	warn sprintf($fmt, @_);
}

1;
