#*********************************************************************
#*** ResourcePool
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: ResourcePool.pm,v 1.23 2002/06/03 19:16:00 mws Exp $
#*********************************************************************

######
# TODO
#
# -> sleep between Try's
# -> statistics function
# -> DEBUG option to find "lost" resources (store backtrace of get() call
#    and dump on DESTROY)
# -> NOTIFYing features

package ResourcePool;

use strict;
use vars qw($VERSION @ISA);
use ResourcePool::Singelton;
BEGIN { 
	# make script using Time::HiRes, but not fail if it isn't there
	eval "use Time::HiRes qw(sleep)";
}


push @ISA, "ResourcePool::Singelton";
$VERSION = "0.9904";
 
sub new($$@) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $factory = shift;
	my $self;
	my $i;
	$self = $class->SUPER::new("ResourcePool::".$factory); # Singelton

	if (!exists($self->{Factory})) {
		$self->{Factory} = $factory;
		$self->{FreePool} = [];
		$self->{UsedPool} = [];
		my %options = (
			Max => 5,
			Min => 1,
			MaxTry => 2,
			PreCreate => 0,
			SleepOnFail => [0], 
			@_, #override defaults with actual parameters
		);
		# prepare SleepOnFail parameter, extend if neccessary
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
		
		$self->{Max}			= $options{Max};
		$self->{Min}			= $options{Min};
		$self->{MaxTry}			= $options{MaxTry};
		$self->{PreCreate}		= $options{PreCreate};
		$self->{SleepOnFail}	= [reverse @{$options{SleepOnFail}}];

		bless($self, $class);
		for ($i = $self->{PreCreate}; $i > 0; $i--) {
			$self->inc_pool();
		}
	} 
 
	return $self;
}

sub get($) {
	my ($self) = @_;
	my $rec = undef;
	my $maxtry = $self->{MaxTry} - 1;

	do {
		if (scalar(@{$self->{FreePool}}) < 1) {
			$self->inc_pool();
		}
		if (scalar(@{$self->{FreePool}}) >= 1) {
			$rec = shift @{$self->{FreePool}};	
			push @{$self->{UsedPool}}, $rec;

			if (! $rec->precheck()) {
				swarn("ResourcePool(%s): precheck failed\n",
					$self->{Factory}->info());
				$rec->fail_close();
				drop_from_list($rec, $self->{UsedPool});
				undef $rec;
			}
		} 
	} while (! defined $rec &&  ($maxtry-- > 0) && ($self->sleepit($maxtry)));
	return defined $rec ? $rec->get_plain_resource(): undef;
}

sub free($$) {
	my ($self, $plain_rec) = @_;
	my $rec = $self->get_rec($plain_rec);
	if (drop_from_list($rec, $self->{UsedPool})) {
		if ($rec->postcheck()) {
			push @{$self->{FreePool}}, $rec;
		} else {
			$rec->fail_close();
		}
	}
	return undef;
}

sub fail($$) {
	my ($self, $plain_rec) = @_;
	my $rec = $self->get_rec($plain_rec);
	swarn("ResourcePool(%s): got failed resource from client\n",
		$self->{Factory}->info());
	if (drop_from_list($rec, $self->{UsedPool})) {
		$rec->fail_close();
	}
	return undef;
}

sub downsize($) {
	my ($self) = @_;
	my $rec;

	swarn("ResourcePool(%s): Downsizing\n", $self->{Factory}->info());
	while ($rec =  shift(@{$self->{FreePool}})) {
		#drop_from_list($rec, $self->{FreePool});
		$rec->close();
	}
	swarn("ResourcePool: Downsized... still %s open (%s)\n",
		scalar(@{$self->{UsedPool}}), scalar(@{$self->{FreePool}}));
	
}

sub postfork($) {
	my ($self) = @_;
	my $rec;
	$self->{FreePool} = [];
	$self->{UsedPool} = [];
}

sub info($) {
	my ($self) = @_;
	return $self->{Factory}->info();
}

sub setMin($$) {
	my ($self, $min) = @_;
	$self->{Min} = $min;
	return 1;
}

sub setMax($$) {
	my ($self, $max) = @_;
	$self->{Max} = $max;
	return 1;
}

sub print_status($) {
	my ($self) = @_;
	printf("\t\t\t\t\tDB> FreePool: <%d>", scalar(@{$self->{FreePool}}));
	printf(" UsedPool: <%d>\n", scalar(@{$self->{UsedPool}}));
}

sub get_stat_used($) {
	my ($self) = @_;
	return scalar(@{$self->{UsedPool}});
}

sub get_stat_free($) {
	my ($self) = @_;
	return scalar(@{$self->{FreePool}});
}

#*********************************************************************
#*** Private Part
#*********************************************************************

sub inc_pool($) {
	my ($self) = @_;
	my $rec;	
	my $PoolSize;

	$PoolSize=scalar(@{$self->{FreePool}}) + scalar(@{$self->{UsedPool}});

	if ( (! defined $self->{Max}) || ($PoolSize < $self->{Max})) {
		$rec = $self->{Factory}->create_resource();
	
		if (defined $rec) {
			push @{$self->{FreePool}}, $rec;
		}	
	}
}

sub get_rec($$) {
	my ($self, $plain_res) = @_;
	my $item;

	foreach $item (@{$self->{UsedPool}}) {
		if ($item->get_plain_resource() eq $plain_res) {
			return $item;
		}
	}
}

sub sleepit($$) {
	my ($self, $try) = @_;
	swarn("ResourcePool> sleeping %s seconds...\n", $self->{SleepOnFail}->[$try]);
	sleep($self->{SleepOnFail}->[$try]);
	$self->downsize();
	return 1;
}


#*********************************************************************
#*** Functional Part
#*********************************************************************

sub drop_from_list($$) {
	my ($val, $list_ref) = @_;
	my $item;
	my @new = ();
	my $found = 0;
	
	foreach $item (@{$list_ref}) {
		if ($item ne $val) {
			push @new, $item;
		} else {
			$found = 1;
		}
	}

	if ($found) {
		@{$list_ref} = @new;
	} 
	return $found;
}

sub swarn($@) {
	my $fmt = shift;
	warn sprintf($fmt, @_);
}

1;

__END__

=head1 NAME

ResourcePool - A connection caching and pooling class.

=head1 SYNOPSIS

 use ResourcePool;
 use ResourcePool::Factory;

 my $factory = ResourcePool::Factory->new();
 my $pool = ResourcePool->new($factory, @Options);

 my $resource = $pool->get();  # get a resource out of the pool
 [...]                         # do something with $resource
 $pool->free($resource);       # give it back to the pool

 $pool->fail($resource);       # give back a failed resource

=head1 DESCRIPTION

The ResourcePool is a generic connection caching and pooling management 
facility. It might be used in an Apache/mod_perl environment to support
connection caching like Apache::DBI for non-DBI resources (e.g. Net::LDAP).
It's also useful in a stand alone perl application to handle connection pools.

The key benefit of ResourcePool is the generic design which makes it easily
extendable to new resource types.

The ResourcePool has a simple check mechanism to detect and close 
broken connections (e.g. if the database server was restarted) 
and opens new connections if possible.

The ResourcePool itself handles always exactly equivalent connections (e.g.
connections to the same server whith the same username and password) and is 
therefore not able to do a loadbalancing. The ResourcePool::LoadBalancer class
is able to do a simple load balancing across different servers and increases
the overall availibility by detecting dead servers.

=head2 S<ResourcePool-E<gt>new($factory, [@Options])>

Creates a new ResourcePool. It uses a previous created ResourcePool if 
possible. So if you call the new method with the same arguments twice, 
the second call returns the same reference as the first did.
This is even true if you call the new method while handling different 
Apache/mod_perl requests (as long as they are in the same Apache process). 
(This is implemented using the Singelton class included in this distribution)

=over 4

=item $factory

A Factory is required to create new resources on demand. The Factory is the 
place where you configure the resources you plan to use (e.g. Database server,
username and password). Since the Factory is specific to the actual resource you
want to use, there are different factories for the different resource type under the
ResourcePool::Factory tree. (see L<ResourcePool::Factory>)

=back

=head2 OPTIONS

=over 4

=item B<Max>

Specifies the maximum concurrent resources managed by this pool.
If the limit is reached the get() method will return undef.

Default: 5

=item B<MaxTry>

Specifies how many dead Resources the get() method checks before 
it returns undef.
Normally the get() method doesn't return dead resources (e.g. broken 
connections). In the case there is a broken connection in the pool, the
get() method throws it away and takes the next resource out of the pool.
The get() method tries not more then B<MaxTry> resources before it returns undef.

Default: 2

=item B<PreCreate>

Normally the ResourcePool creates new resources only on demand, with this 
option you can specify how many resources are created when the ResourcePool
gets constructed.

Default: 0

=item B<SleepOnFail>

You can tell the ResourcePool to sleep a while when a dead resource was found.
Normally the get() method tries up to B<MaxTry> times to get an valid resource 
for you without any delay between the tries. This is usually not what you want
if you database is not available for a short time. Using this option you
can specify a list of timeouts which should be slept between two tries to get
an valid resource. If you have specified 

 MaxTry => 5
 SleepOnFail => [0, 1, 2, 4]

ResourcePool would do the following if it isn't able to get an valid resource:

 try to get resource -> failed
 sleep 0
 try to get resource -> failed
 sleep 1
 try to get resource -> failed
 sleep 2
 try to get resource -> failed
 sleep 4
 try to get resource -> failed
 return undef 

So this call to get() would have taken about 7 seconds. 

Using an exponential time scheme like this one, is usually the most efficient. 
However it is highly recommeded to leave the first value always "0" since 
this is required to allow the ResourcePool to try to establish a new connection 
without delay. 

The number of sleeps can not be more than MaxTry - 1, 
if you specify more values the list is truncated.
If you specify less values the list is extended using the last value for the extended elements. e.g. [0,1] in the above example would have been extended to [0, 1, 1, 1]

If you have Time::HiRes installed on your system, you can specify a fractal number of seconds.

If you use ResourcePool::LoadBalancer you should use LoadBalancer's SleepOnFail option instead of this one.

Please see also L</TIMEOUTS> for more information about timeouts.

Default: [0]

=back

=head2 S<$pool-E<gt>get>

Returns a resource. This resource has to be given back via the free() or fail()
method. 
The get() method calls the precheck() method of the according Resource 
(see ResourcePool::Resource) to determine if a resource is valid.
The get() method may return undef if there is no valid resource available. 
(e.g. because the B<Max> or the B<MaxTry> values are reached)

=head2 S<$pool-E<gt>free($resource)>

Returns a resource to the pool. This resource will be re-used by get() calls.
The free() method calls the postcheck() method of the Resource to dertermine if
the resource is valid.

=head2 S<$pool-E<gt>fail($resource)>

Marks a resource as bad. The ResourcePool will throw this resource away and
NOT return it to the pool of available connections.

=head1 EXAMPLE

This section includes a typical configuration for a persistent Net::LDAP pool.

 use ResourcePool;
 use ResourcePool::Factory::Net::LDAP;

 my $factory =  ResourcePool::Factory::Net::LDAP->new("ldaphost",
                  [ dni => 'cn=Manager,dc=fatalmind,dc=com',
                    password => 'secret', [version => 2]]);

 my $pool = ResourcePool->new($factory, MaxTry => 5, 
                  SleepOnFail => [0,1,2,4]);

 if ($something) {
    my $ldaph = $pool->get();

    # do something useful with $ldaph

    $pool->free($ldaph);
 }

 # some code nothing to do with ldap

 if ($somethingdifferent) {
    my $ldaph = $pool->get();

    # do something different with $ldaph

    $pool->free($ldaph);
 }


So, lets sum up some characteristics of this example:

=over 4

=item There is only one connection

Even if $something AND $somethingdifferent are true, 
there is only one connection to the ldaphost 
opend during the run of this script.

=item Connections are created on demand

If neighter $something nor $somethingdifferent are true, there is
NO connection to ldaphost opend for this script. 
This is very nice for script which MIGHT need a connection, and MIGHT 
need this connection on some different places. You can save a lot of

 if (! defined $ldaph) {
 	# your connection code goes here
 }

stuff.

It much more convinient to pass a single argument (e.g. $pool) to a function 
than passing all the credentials.

If you want to make sure that there is always a connection opend, you can use

 PreCreate => 1

=item Connections are persistent in Apache/mod_perl environment

If you would use a script like the one above in an Apache/mod_perl
environment, the created pool would be persistent across different
script invocations within one Apache process.

So, the connection establishment overhead would only occure once for
each Apache process. This is very much like Apache::DBI, but 
much more generic.

=item Covers serveroutages

As long as the ldaphost doesn't crash while you are actually using 
it (between get() and free()) the ResourcePool would transperently
cover any ldaphost outages which take less then 7 seconds.

You can easily change the time how long ResourcePool tries to create
a connection with the B<MaxTry> and B<SleepOnFail> options. If you would have
used 
 
 MaxTry => 1000000

in the example above, the get() method could have blocked for about 46 days
until giving up (after the first 3 tries it would have tried every 4 seconds 
to establish a connection).

If you have a connection problem with the resource while using it, it's the
best practice to give it back to the pool using the fail() method. In that
case the ResourcePool just throws it away. After that you can try again to 
get() a new resource.

=back

=head1 TIMEOUTS

Time to say some more words about timeouts which take place in the get()
method. As you have seen above you can configure this timeouts with
the B<SleepOnFail> option, but thats only the half truth. As the name
of the option says, thats only the time which is actually slept if a try
to obtain a vailid resource failes. But there is also the time which is 
needed to try to obtain a vailid resource. And this time might vary in 
a very wide range. 

Imagine a situation where you have a newly created
ResourcePool for a database (without PreCreate) 
and call the get() method for the first
time. Obviously the ResourcePool has to establish a new connection to the
database. But what happens if the database is down? Then the time which
is needed to recognize that the database is down does also block the get() 
call. Thats usually not a problem if the Operating System of the database 
server is up and only the database application is down. In that case the 
Operating System rejects the connection activly and the connection 
establishment will fail very fast. But it's very different if the Operating 
System is also not available (hardware down, network down,...), 
in that case it might take several seconds 
(or even minutes!!) before the connection establishment fails, because 
it has to wait for internal timeouts (which are not affected by ResourcePool).
Another example is if your DNS server is down, it might also take a long time
before the establishment fails. The usual DNS resolver tries more then one 
minute  before it gives up.

Therefore you have to keep in mind that the timeouts configured via
B<SleepOnFail> are only minimal values. If you configure a B<SleepOnFail>
value of one second between the attempts, than you have a guarantee the
there is at least a sleep of one second between the attempts.

If you want to limit the overall timeouts you have two choices. 1. Use the
timeout functionality of the underlaying modules. This is not always safe
since the modules might use some functions which do not implement a 
configureable timeout or does just not use it. 2. Implement your own timeout
using alarm(). Thats also not safe, since there is no gurantee that a blocking
systemcall gets interrupted when a signal is received. But to my knowledge thats 
still the more reliable variant.

The best way of handling this timeouts is to avoid them. For a High 
Availibility configuration it is important do fail very fast to be
effective. But thats easy to say...

=head1 LIMITATIONS

=over 4

=item Not transparent

Since the main goal of the ResourcePool implementation is to be
generic for any resource types you can think of, it is not possible 
to implement features which need knowledge of the used resource types.

For this reason ResourcePool leaves you allone as soon as you have obtained 
a resource until you give it back to the pool (between get() and free() or 
fail()).

ResourcePool does not magically modify DBI or Net::LDAP to do a transparent 
reconnect if one connection failes while you are using it. The smartness
of ResourcePool lies in the get() method, therefore you must keep the
resources as short as possible outside of the pool and obtain a resource
via get() if you need one.

But you have also to be careful to do too many get()/free() calls since this
might also cause a overhead because of the precheck() and postcheck() methods.

=item Pools are not shared across different processes

The use of fork() and ResourcePool is only safe if there are no open 
resources (connections) when you are doing the fork.

Even if it sounds very invitingly to create a ResourcePool with some
PreCreated connections and afterwards doing the fork, its just not save.
Thats for several reasons: 1. There is no locking between the different
processes (the same resource could be used more then once simultaneously).
2. There is no guarantee the the underlaying implementations do not keep
some state-information localy (this could case protocol errors). 
3. I't impossible to share newly 
opend connection with the other processes.

If you try to pass some open resources through fork() you are alone!
You will have some funny effects which will cost you a lot of time
tracking down until you finally give up. And please, do not even think
of asking for help as long as you do pass open resources through 
fork.

=back

=head1 SEE ALSO

L<ResourcePool::LoadBalancer(3pm)>, 
L<ResourcePool::Resource(3pm)>, 
L<ResourcePool::Factory(3pm)>,
L<ResourcePool::Factory::DBI(3pm)>, 
L<ResourcePool::Factory::Net::LDAP(3pm)>

=head1 AUTHOR

    Copyright (C) 2002 by Markus Winand <mws@fatalmind.com>

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.


