#*********************************************************************
#*** ResourcePool::LoadBalancer
#*** Copyright (c) 2001 by Markus Winand <mws@fatalmind.com>
#*** $Id: LoadBalancer.pm,v 1.5 2001/10/15 19:24:20 mws Exp $
#*********************************************************************

package ResourcePool::LoadBalancer;

use strict;
use vars qw($VERSION @ISA);
use ResourcePool::Singelton;

push @ISA, "ResourcePool::Singelton";
$VERSION = "0.9903";

sub new($$@) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $key = shift;
	my $self;

	$self = $class->SUPER::new("LoadBalancer". $key); # Singelton

	if (! exists($self->{Policy})) {
		$self->{key} = $key;
		$self->{PoolArray} = (); # empty pool list
		$self->{PoolHash} = (); # empty pool hash
		$self->{UsedPool} = (); # mapping from plain_resource to
					# rich pool
		$self->{Next} = 0;
		my %options = (
			Policy => "LeastUsage",
			MaxTry => 2,
			# RoundRobin, LeastUsage, FallBack
			@_
		);
		$self->{Policy} = $options{Policy};
		$self->{MaxTry} = $options{MaxTry};
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
		UsageCount	=> 0,
		@_
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
	my $r_pool;

	if ($self->{Policy} eq "FallBack") {
		($rec, $r_pool) = $self->get_fallback();
	} else {
		do {
			if ($self->{Policy} eq "RoundRobin") {
				($rec, $r_pool) = $self->get_next();
			} elsif ($self->{Policy} eq "LeastUsage") {
			($rec, $r_pool) = $self->get_least();
			}
		} while (! defined $rec && ($maxtry-- > 0));
	}
	if (defined $rec) {
		$self->{UsedPool}->{$rec} = $r_pool;
	}
	return $rec;
}

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

sub get_least($) {
	my ($self) = @_;
	my ($rec, $pool);
	my ($least_val, $least_r_pool);
	my ($least_usage, $least_usage_r_pool);
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
	$rec = $least_r_pool->{pool}->get();
	if (! defined $rec) {
		$self->suspend($least_r_pool);
		undef $rec;
		undef $r_pool;
	} else {
		$least_r_pool->{UsageCount} += $least_r_pool->{Weight};
	}
	return ($rec, $least_r_pool);		
}

sub get_fallback($) {
	my ($self) = @_;
	my ($rec, $r_pool);
	my $i = 0;

	do {
		$r_pool = $self->{PoolArray}->[$i];	
		if (! $self->chk_suspend($r_pool)) {
			$rec = $r_pool->{pool}->get();
			if (! defined $rec) {
				$self->suspend($r_pool);
			}
		} else {
			undef $rec;
		}
	} while (! defined $rec && ++$i < scalar(@{$self->{PoolArray}}));
	if (defined $self->{LastUsedPool} && $r_pool ne $self->{LastUsedPool}) {
		$self->{LastUsedPool}->{pool}->downsize();
	}
	$self->{LastUsedPool} = $r_pool;
	if (! defined $rec) {
		undef $r_pool;
	}
	return ($rec, $r_pool);
}

sub free($$) {
	my ($self, $rec) = @_;
	my $r_pool;

 	$r_pool = $self->{UsedPool}->{$rec};	
	$r_pool->{pool}->free($rec);
	if ($self->chk_suspend_no_recover($r_pool)) {
		$r_pool->{pool}->downsize();
	}
	if ($self->{Policy} eq "FallBack") {
		if ($r_pool ne $self->{LastUsedPool}) {
			$self->{LastUsedPool}->{pool}->downsize();
		}
	}
	undef $self->{UsedPool}->{$rec};
}

sub fail($$) {
	my ($self, $rec) = @_;

 	$self->{UsedPool}->{$rec}->{pool}->fail($rec);	
	undef $self->{UsedPool}->{$rec};
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
}

sub chk_suspend($$) {
	my ($self, $r_pool) = @_;
#	my $r_pool = $self->{PoolHash}->{$pool};

	if ($self->chk_suspend_no_recover($r_pool)) {
		if ($r_pool->{Suspended} <= time()) {
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

sub swarn($@) {
	my $fmt = shift;
	warn sprintf($fmt, @_);
}

1;


__END__

=head1 NAME

ResourcePool::LoadBalancer - A LoadBalancer across ResourcePools.

=head1 SYNOPSIS

 use ResourcePool::LoadBalancer;

 my $loadbalancer = ResourcePool::LoadBalancer->new($key, @options);


 $loadbalancer->add_pool($some_ResourcePool);
 $loadbalancer->add_pool($some_other_ResourcePool);
 $loadbalancer->add_pool($third_ResourcePool);

 
 my $resource = $loadbalancer->get();  # get a resource of of one pools
                                       # according to the policy
 [...]				       # do something with $resource
 $loadbalancer->free($resource);       # give it back to the pool

 $loadbalancer->fail($resource);       # give back a failed resource

=head1 DESCRIPTION

The LoadBalancer is a generic way to spread requests to different ResourcePools
to increase performance and/or availibility.

Besides the construction the interface of a LoadBalancer is the same as the 
interface of a ResourcePool. This makes it very simple to replace a existing
ResourcePool with a LoadBalancer.

The methods of the LoadBalancer follow now in order of usage, please have a 
look at the EXAMPLE below if you have still questions.

=head2 LoadBalancer->new()

Creates a new LoadBalancer. This method takes one key to identify the 
LoadBalancer (used by ResourcePool::Singelton). It is recommended to use
some meaningful string as key, since this is used when errors are reported.
This key is internally used to distingush between different pool types, e.g.
if you have to LoadBalancer one for DBI connections to different servers and
use parallel another LoadBalancer for Net::LDAP connections.

=head2 Options

=over 4

=item Policy

With this option you can specify which ResourcePool is used if you ask
the LoadBalancer for a Resource. B<LeastUsage> takes always the ResourcePool
with the least used Resources. This is usually a vital inidcator for the
machine with the least load. B<RoundRobin> iterates over all available
ResourcePools regardless of the usage of the ResourcePools. B<FallBack> uses
always the first ResourcePool if it works, only if there is a problem it 
takes the second and so on.

In every case the LoadBalancer tries to find a valid Resource for you.

Default: LeastUsage

=item MaxTry

The MaxTry option specifies how many ResourcePools the LoadBalancer queries
before it gives up and return a null on the get() call.
This option is identical to the same named option from the ResourcePool.

Default: 2

=head2 $loadbalancer->add_pool($resourcepool, @options)

Adds a ResourcePool object to the LoadBalancer. You must call this method 
multiple to add more Pools.

There are two options which affect the way the LoadBalancer selects the
ResourcePools. B<Weight> may make one ResourcePool more relevant then others. 
A ResourcePool with a high Weight is more expancive then a ResourcePool with
a low Weight and will be used less frequent by the LoadBalancer.
B<SuspendTimeout> specifies the timeout in seconds, see below.

Defaults: Weight = 100, SuspendTimout = 5

=head2 $loadbalancer->get()

Returns a resource. This resource has to be given back via the free() or fail()
method. 
The get() method calls the get() method of the ResourcePool and might therfore
return undef if no valid resource could be found in the ResourcePool. In
that case the LoadBalancer tries up to MaxTry times to get a valid resource
out of the ResourcePools. 
If the LoadBalancer finds a invalid ResourcePool (a ResourcePool which returns
a undef) it suspends this ResourcePool and re-applies the Policy to get a valid
resource. The B<SuspendTimeout> is configureable on a per-ResourcePool basis.

=head2 $loadbalancer->free($resource)

Returns a resource to the ResourcePool it comes from. Basically the same
as the free() method of the ResourcePool.

=head2 $loadbalancer->fail($resource)

Maks the resource as bad. Basically the same as the fail() method of the
ResourcePool.

=head1 EXAMPLE


 use ResourcePool;
 use ResourcePool::Factory::Net::LDAP;
 use ResourcePool::LoadBalancer;

 # create a pool to a ldap server
 my $factory1 = ResourcePool::Factory::Net::LDAP->new("ldap.domain.com");
 my $pool1    = ResourcePool->new($factory1);

 # create a pool to another ldap server
 my $factory2 = ResourcePool::Factory::Net::LDAP->new("backupldap.domain.com");
 my $pool2    = ResourcePool->new($factory1);

 # create a empty loadbalancer with a FallBack policy
 my $loadbalancer = ResourcePool::LoadBalancer->new("LDAP", "FallBack");

 # add the first pool to the LoadBalancer
 # since this pool was configured to use the FallBack policy, this is
 # the primary used pool
 $loadbalancer->add_pool($pool1);

 # add the second pool to the LoadBalancer.
 # This pool is only used when first pool failes
 $loadbalancer->add_pool($pool2);

 
 my $resource = $loadbalancer->get();  # get a resource of of one pools
                                       # according to the policy
 [...]				       # do something with $resource
 $loadbalancer->free($resource);       # give it back to the pool

 $loadbalancer->fail($resource);       # give back a failed resource

=head1 SEEL ALSO

ResourcePool(3pm)

=head1 AUTHOR

    Copyright (C) 2001 by Markus Winand <mws@fatalmind.com>

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.
