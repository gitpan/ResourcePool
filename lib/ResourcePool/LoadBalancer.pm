#*********************************************************************
#*** ResourcePool::LoadBalancer
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: LoadBalancer.pm,v 1.19.2.1 2002/08/30 16:25:11 mws Exp $
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
$VERSION = "0.9907";

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


__END__

=head1 NAME

ResourcePool::LoadBalancer - A LoadBalancer across ResourcePools

=head1 SYNOPSIS

 use ResourcePool::LoadBalancer;

 my $loadbalancer = ResourcePool::LoadBalancer->new($key, @options);


 $loadbalancer->add_pool($some_ResourcePool);
 $loadbalancer->add_pool($some_other_ResourcePool);
 $loadbalancer->add_pool($third_ResourcePool);

 
 my $resource = $loadbalancer->get();  # get a resource from one pool
                                       # according to the policy
 [...]				       # do something with $resource
 $loadbalancer->free($resource);       # give it back to the pool

 $loadbalancer->fail($resource);       # give back a failed resource

=head1 DESCRIPTION

The LoadBalancer is a generic way to spread requests to different ResourcePools
to increase performance and/or availability.

Beside the construction the interface of a LoadBalancer is the same as the 
interface of a ResourcePool. This makes it very simple to change a program 
which uses ResourcePool to use the LoadBalancer by just changing the
construction (which is hopefully kept at a central point in your program).

=head2 S<LoadBalancer-E<gt>new($key, [@Options])>

Creates a new LoadBalancer. This method takes one key to identify the 
LoadBalancer (used by ResourcePool::Singleton). It is recommended to use
some meaningful string as key, since this is used when errors are reported.
This key is internally used to distingush between different pool types, e.g.
if you have two LoadBalancer one for DBI connections to different servers and
use parallel another LoadBalancer for Net::LDAP connections.

=head2 Options

=over 4

=item B<Policy>

With this option you can specify which ResourcePool is used if you ask
the LoadBalancer for a resource. B<LeastUsage> takes always the ResourcePool
with the least used resources. This is usually a vital inidcator for the
machine with the lowest load. B<RoundRobin> iterates over all available
ResourcePools regardless of the usage of the ResourcePools. B<FallBack> uses
always the first ResourcePool if it works, only if there is a problem it 
takes the second one (and so on).

In every case the LoadBalancer tries to find a valid resource for you,
this option only affects the order in which the ResourcePools are checked.

Default: C<LeastUsage>

=item B<MaxTry>

The MaxTry option specifies how often the LoadBalancer checkes all it's 
ResourcePools for a valid resource before it gives up and returns undef on 
the get() call.
This option is similar to the same named option from the ResourcePool.

Default: 6

=item B<SleepOnFail>

Very similar to the same named option from ResourcePool. Tells the LoadBalancer
to sleep if it was not able to find a valid resource in ANY of the underlying 
ResourcePools. So, in the worst case, get() tries all ResourcePools 
(all which are not suspended) to obtain a valid resource, if this fails it 
sleeps. After this sleep all pools are checked again and if it was still not
possible to get a vaild resource it sleeps again. This is done up to 
B<MaxTry> times before get() returns undef.

With this option you can specify the time in seconds which will be slept if
it was not possible to obtain a valid resource from any of the ResourcePools.

Default: [0,1,2,4,8]

=back

=head2 S<$loadbalancer-E<gt>add_pool($resourcepool, @options)>

Adds a ResourcePool object to the LoadBalancer. You must call this method 
multiple times to add more pools.

There are two options which affect the way the LoadBalancer selects the
ResourcePools. B<Weight> may make one ResourcePool more relevant then others. 
A ResourcePool with a high Weight is more expansive then a ResourcePool with
a low Weight and will be used less frequent by the LoadBalancer.
B<SuspendTimeout> specifies the timeout in seconds if this 
ResourcePool returns a undef, see below.

You can add as many ResourcePools as you want.

Defaults: Weight = 100, SuspendTimeout = 5

=head2 S<$loadbalancer-E<gt>get>

Returns a resource. This resource has to be given back via the free() or fail()
method. 
The get() method calls the get() method of the ResourcePool and might therefore
return undef if no valid resource could be found in the ResourcePool. In
that case the LoadBalancer tries up to MaxTry times to get a valid resource
out of the ResourcePools. 
If the LoadBalancer finds a invalid ResourcePool (a ResourcePool which returns
a undef) it suspends this ResourcePool and re-applies the Policy to get a valid
resource. The B<SuspendTimeout> is configureable on a per ResourcePool basis.

According to the B<MaxTry> and B<SleepOnFail> settings the get() call might block
the programs execution if it is not able to find a valid resource right now.
Provided that you use the default settings for B<MaxTry> and B<SleepOnFail> a call
to get() will block at least for 15 seconds before returning undef.
Please see L<ResourcePool/"TIMEOUTS"> for some other effects which might affect
the time which get() blocks before it returns undef.

=head2 S<$loadbalancer-E<gt>free($resource)>

Marks a resource as free. Basically the same
as the free() method of the ResourcePool.
Return value is 1 on success or 0 if the resource doesn't belong to 
one of the underlieing pools.

=head2 S<$loadbalancer-E<gt>fail($resource)>

Maks the resource as bad. Basically the same as the fail() method of the
ResourcePool.
Return value is 1 on success or 0 if the resource doesn't belong to 
one of the underlieing pools.

=head1 EXAMPLE

A basic example...

 use ResourcePool;
 use ResourcePool::Factory::Net::LDAP;
 use ResourcePool::LoadBalancer;

 ### LoadBalancer setup 

 # create a pool to a ldap server
 my $factory1 = ResourcePool::Factory::Net::LDAP->new("ldap.you.com");
 my $pool1    = ResourcePool->new($factory1);

 # create a pool to another ldap server
 my $factory2 = ResourcePool::Factory::Net::LDAP->new("ldap2.you.com");
 my $pool2    = ResourcePool->new($factory2);

 # create a empty loadbalancer with a FallBack policy
 my $loadbalancer = ResourcePool::LoadBalancer->new("LDAP", 
                        Policy => "FallBack");

 # add the first pool to the LoadBalancer
 # since this LoadBalancer was configured to use the FallBack
 # policy, this is the primary used pool
 $loadbalancer->add_pool($pool1);

 # add the second pool to the LoadBalancer.
 # This pool is only used when first pool failes
 $loadbalancer->add_pool($pool2);

 ### LoadBalancer usage (no difference to ResourcePool)
 
 for (my $i = 0; $i < 1000000 ; $i++) {
    my $resource = $loadbalancer->get();  # get a resource from one pool
                                          # according to the policy
	if (defined $resource) {
       eval {
          #[...]                          # do something with $resource
          $loadbalancer->free($resource); # give it back to the pool
       }; 
       if ($@) { # an exception happend
          $loadbalancer->fail($resource); # give back a failed resource
       }
	} else {
	   die "The LoadBalancer was not able to obtain a valid resource\n";
    }
 }

Please notice that the get()/free() stuff in this example in INSIDE the 
loop. This is very important to make sure the loadbalacing and failover 
works. As for the ResourcePool the smartness of the LoadBalancer lies
in the get() method, so if you do not call the get() method regulary
you can not expect the LoadBalancer to handle loadbalancing or failover.

The example above does not do any loadbalancing since the policy was set
to FallBack. If you would change this to RoundRobin or LeastUsage you
would spread the load across both servers.

You can directly copy and past the example above and try to run it. If 
you do not change the hostnames you will just see how it fails,
but even this will tell you a lot about how it works. Give it a try.

Now lets make a slightly more complex configuration. Imagine you have 
three ldap servers: one master where you do your write access, two 
replicas where you do the read access. Now we want the ResourcePool
to implement a loadbalacing across the two replicas but we want it
to use the master also for read access if both replicas are not available.

This setup is simple if you keep in mind what I have said about the
LoadBalancer interface: "Beside the construction the interface 
of a LoadBalancer is the same as the interface of a ResourcePool". 
This means that it is possible to make a nested LoadBalacer chain.

 use ResourcePool;
 use ResourcePool::Factory::Net::LDAP;
 use ResourcePool::LoadBalancer;

 ### LoadBalancer setup 

 # create a pool to the master
 my $masterfactory   = ResourcePool::Factory::Net::LDAP->new("master");
 my $master          = ResourcePool->new($masterfactory);

 # create pools to the replicas
 my $replica1factory = ResourcePool::Factory::Net::LDAP->new("replica1");
 my $replica1        = ResourcePool->new($replica1factory);

 my $replica2factory = ResourcePool::Factory::Net::LDAP->new("replica2");
 my $replica2        = ResourcePool->new($replica2factory);

 # create the loadbalacer to spread load across the two replicas
 # using the default Policy LeastUsage
 my $replicaLB       = ResourcePool::LoadBalancer->new("LDAP-Replica");
 $replicaLB->add_pool($replica1);
 $replicaLB->add_pool($replica2);

 # create a suprior loadbalancer which handels the fallback to the
 # master if both replicas fail.
 my $loadbalancer = ResourcePool::LoadBalancer->new("LDAP", 
                        Policy => "FallBack");
 $loadbalancer->add_pool($replicaLB);   # HERE IS THE MAGIC
 $loadbalancer->add_pool($master);

 ### LoadBalancer usage is the same as above, therfore skipped here 

You should keep in mind that this configuration causes a multiplication
of the timeout's which are done because of the B<SleepOnFail> settings.
In the example above the sleeps sum up to 60 seconds.


=head1 SEEL ALSO

L<ResourcePool(3pm)>

=head1 AUTHOR

    Copyright (C) 2002 by Markus Winand <mws@fatalmind.com>

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.
