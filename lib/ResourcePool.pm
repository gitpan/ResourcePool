#*********************************************************************
#*** ResourcePool
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: ResourcePool.pm,v 1.33 2002/09/02 10:22:57 mws Exp $
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
use ResourcePool::Singleton;
BEGIN { 
	# make script using Time::HiRes, but not fail if it isn't there
	eval "use Time::HiRes qw(sleep)";
}


push @ISA, "ResourcePool::Singleton";
$VERSION = "0.9908";
 
sub new($$@) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $factory = shift;
	my $self;
	my $i;
	$self = $class->SUPER::new("ResourcePool::".$factory); # Singleton

	if (!exists($self->{Factory})) {
		$self->{Factory} = $factory;
		$self->{FreePool} = [];
		$self->{UsedPool} = [];
		my %options = (
			Max => 5,
			Min => 1,
			MaxTry => 2,
			PreCreate => 0,
			SleepOnFail => [0]
		);
		if (scalar(@_) == 1) {
			%options = ((%options), %{$_[0]});
		} elsif (scalar(@_) > 1) {
			%options = ((%options), @_);
		}
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
		return 1;
	} else {
		return 0;
	}
}

sub fail($$) {
	my ($self, $plain_rec) = @_;
	my $rec = $self->get_rec($plain_rec);
	swarn("ResourcePool(%s): got failed resource from client\n",
		$self->{Factory}->info());
	if (drop_from_list($rec, $self->{UsedPool})) {
		$rec->fail_close();
		return 1;
	} else {
		return 0;
	}
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
