#! /usr/bin/perl -w
#*********************************************************************
#*** t/03ResourcePoolSingleton.t
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: 03ResourcePoolSingleton.t,v 1.6 2002/10/06 12:21:41 mws Exp $
#*********************************************************************
use strict;
use Test;
BEGIN {
	eval "use DBI;";
	eval "use Net::LDAP;";
}
use ResourcePool;
if (exists $INC{"DBI.pm"}) {
	require  ResourcePool::Factory::DBI;
} elsif (exists $INC{"Net/LDAP.pm"}) {
	require  ResourcePool::Factory::Net::LDAP;
}

BEGIN { plan tests => 2; };

my ($f1, $f2, $f3);
if (exists $INC{"DBI.pm"}) {
	$f1 = new ResourcePool::Factory::DBI->new("DataSource1", "user", "pass");
	$f2 = new ResourcePool::Factory::DBI->new("DataSource2", "user", "pass");
} elsif (exists $INC{"Net/LDAP.pm"}) {
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

## seperate test, which checks if ResourcePool uses $factory->singleton()
if (exists $INC{"DBI.pm"}) {
	$f1 = new ResourcePool::Factory::DBI->new("DataSource1_new", "user", "pass");
	$f2 = new ResourcePool::Factory::DBI->new("DataSource2_new", "user", "pass");
	$f3 = new ResourcePool::Factory::DBI->new("DataSource1_new", "user", "pass");
} elsif (exists $INC{"Net/LDAP.pm"}) {
	$f1 = new ResourcePool::Factory::Net::LDAP->new("hostname1_new");
	$f2 = new ResourcePool::Factory::Net::LDAP->new("hostname2_new");
	$f3 = new ResourcePool::Factory::Net::LDAP->new("hostname1_new");
}

if (defined $f1) {
my $p1 = ResourcePool->new($f1);
my $p2 = ResourcePool->new($f1);
my $p3 = ResourcePool->new($f2);
my $p4 = ResourcePool->new($f2);
my $p5 = ResourcePool->new($f3);
ok(($p1 == $p2) && ($p1 == $p5) && ($p3 == $p4) && ($p1 != $p3));
} else { skip "skip neither DBI nor Net::LDAP found", 0;}

# TODO, make ResourcePool handle different options with the same internal Pool
