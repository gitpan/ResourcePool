#*********************************************************************
#*** ResourcePool
#*** Copyright (c) 2001 by Markus Winand <mws@fatalmind.com>
#*** $Id: ResourcePool.pm,v 1.11 2001/08/19 10:27:54 mws Exp $
#*********************************************************************

package ResourcePool;

use strict;
use vars qw($VERSION @ISA);
use ResourcePool::Singelton;

push @ISA, "ResourcePool::Singelton";
$VERSION = "0.9903";
 
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
			@_, #override defaults with actual parameters
		);
		$self->{Max}		= $options{Max};
		$self->{Min}		= $options{Min};
		$self->{MaxTry}		= $options{MaxTry};
		$self->{PreCreate}	= $options{PreCreate};

        	bless($self, $class);
		for ($i = $self->{PreCreate}; $i > 0; $i--) {
			printf("DB) pre create: (%s)\n", $i);
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
	} while (! defined $rec &&  ($maxtry-- > 0));
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

ResourcePool - A connection cacheing and pooling class.

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

The ResourcePool is a generic connection cacheing and pooling management 
facility. It might be used in an Apache/mod_perl environment to support
connection caching like Apache::DBI for non-DBI resources (e.g. Net::LDAP).
Its also usefull in a stand alone perl application to handle connection pools.

The key benefit of ResourcePool is the generic design which makes it easily
extendable to new resource types.

The ResourcePool has a simple check mechanism to dedect and close 
broken connections (e.g. if the database server was restarted) 
and opens new connections if possible.

The ResourcePool itself handles always exactly equivalent connections (e.g.
connections to the same server whith the same username and password) and is 
therefore not able to do a loadbalancing. The ResourcePool::LoadBalancer class
is able to do a simple load balancing across different servers and increases
the overall availibility by dedecting dead servers.

=head2 ResourcePool->new()

Creates a new ResourcePool. It uses a previous created ResourcePool if 
possible. So if you call the new method with the same arguments twice, 
the second call returns the ResourcePool created with the first call.
This is even true if you call the new method while handling different 
Apache mod_perl requests. (This is implemented using the Singelton class
included in this distribution)

=over 4

=item $factory

Specifies the Factory to create new resources. (see ResourcePool::Factory)

=head2 OPTIONS

=over 4

=item Max

Specifies the maximum concurrent resources managed by this Pool.
If the limit is reached the get() method may return undef.

Default: 5

=item MaxTry

Specifies how many dead Resources the get() method checks before 
it returns undef.
Normally the get() method doesn't return dead resources (e.g. broken 
connections). In the case there is a broken connection in the Pool, the
get() method throws it away and takes the next resource out of the pool.
The get() method tries not more then MaxTry resources before it returns undef.

Default: 2

=item PreCreate

Specifies how many Resources the Pool creates in advance.

Default: 0

=head2 $pool->get()

Returns a resource. This resource has to be given back via the free() or fail()
method. 
The get() method calls the precheck() method of the according Resource 
(see ResourcePool::Resource) to determine if a resource is valid.
The get() method may return undef if there is no valid resource available. 
(e.g. because the Max or the MaxTry options are reached)

=head2 $pool->free($resource)

Returns a resource to the pool. This resource will be re-used by get() calls.
The free() method calls the postcheck() method of the Resource to dertermine if
the resource is valid.

=head2 $pool->fail($resource)

Marks a resource as bad. The ResourcePool will throw this resource away and
NOT return it to the pool of available connections.


=head1 SEE ALSO

ResourcePool::Resource(3pm), ResourcePool::Factory(3pm),
ResourcePool::Factory::DBI(3pm), ResourcePool::Factory::Net::LDAP(3pm)

=head1 AUTHOR

    Copyright (C) 2001 by Markus Winand <mws@fatalmind.com>

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.


