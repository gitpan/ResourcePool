#! /usr/bin/perl -w
#*********************************************************************
#*** t/03ResourcePoolSingleton.t
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: 03ResourcePoolSingleton.t,v 1.3 2002/07/05 20:32:25 mws Exp $
#*********************************************************************
use strict;
use Test;
BEGIN {
	eval "use ResourcePool::Factory::DBI";
	eval "use ResourcePool::Factory::Net::LDAP";
}
use ResourcePool;

BEGIN { plan tests => 1; };

my ($f1, $f2);
if (exists $INC{"ResourcePool/Factory/DBI.pm"}) {
	$f1 = new ResourcePool::Factory::DBI->new("DataSource1", "user", "pass");
	$f2 = new ResourcePool::Factory::DBI->new("DataSource2", "user", "pass");
} elsif (exists $INC{"ResourcePool/Factory/Net/LDAP.pm"}) {
	$f1 = new ResourcePool::Factory::Net::LDAP->new("hostname1");
	$f2 = new ResourcePool::Factory::Net::LDAP->new("hostname2");
}

if (defined $f1) {
my $p1 = ResourcePool->new($f1);
my $p2 = ResourcePool->new($f1);
my $p3 = ResourcePool->new($f2);
my $p4 = ResourcePool->new($f2);
my $p5 = ResourcePool->new($f1);
ok(($p1 == $p2) && ($p1 == $p5) && ($p3 == $p4) && ($p1 != $p3));
} else { skip "skip neither DBI nor Net::LDAP found", 0;}

# TODO, make ResourcePool handle different options with the same internal Pool
