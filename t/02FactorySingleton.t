#! /usr/bin/perl -w
#*********************************************************************
#*** t/02DBIFactorySingleton.t
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: 02FactorySingleton.t,v 1.7 2002/07/08 20:07:43 mws Exp $
#*********************************************************************
use strict;
use Test;

BEGIN{
	eval "use DBI; use ResourcePool::Factory::DBI;";
	eval "use Net::LDAP; use ResourcePool::Factory::Net::LDAP;"
}

BEGIN { plan tests => 7; };

if (exists $INC{"DBI.pm"}) {
my $f1 = ResourcePool::Factory::DBI->new("DataSource1", "user", "pass");
my $f2 = ResourcePool::Factory::DBI->new("DataSource1", "user", "pass");
my $f3 = ResourcePool::Factory::DBI->new("DataSource2", "user", "pass");
my $f4 = ResourcePool::Factory::DBI->new("DataSource2", "user", "pass");
my $f5 = ResourcePool::Factory::DBI->new("DataSource1", "user", "pass");
ok (($f1 == $f2) && ($f1 == $f5) && ($f3 == $f4) && ($f1 != $f3));
} else { skip "skip DBI not found",0; }

if (exists $INC{"DBI.pm"}) {
my $f1 = ResourcePool::Factory::DBI->new("DataSource", "user1", "pass");
my $f2 = ResourcePool::Factory::DBI->new("DataSource", "user1", "pass");
my $f3 = ResourcePool::Factory::DBI->new("DataSource", "user2", "pass");
my $f4 = ResourcePool::Factory::DBI->new("DataSource", "user2", "pass");
my $f5 = ResourcePool::Factory::DBI->new("DataSource", "user1", "pass");
ok(($f1 == $f2) && ($f1 == $f5) && ($f3 == $f4) && ($f1 != $f3));
} else { skip "skip DBI not found",0; }

if (exists $INC{"DBI.pm"}) {
my $f1 = ResourcePool::Factory::DBI->new("DataSource", "user", "pass");
my $f2 = ResourcePool::Factory::DBI->new("DataSource", "user", "pass");
my $f3 = ResourcePool::Factory::DBI->new("DataSource", "user", "pass", {AutoCommit => 1});
my $f4 = ResourcePool::Factory::DBI->new("DataSource", "user", "pass", {AutoCommit => 1});
my $f5 = ResourcePool::Factory::DBI->new("DataSource", "user", "pass");
ok(($f1 == $f2) && ($f1 == $f5) && ($f3 == $f4) && ($f1 != $f3));
} else { skip "skip DBI not found",0; }

if (exists $INC{"Net/LDAP.pm"}) {
my $f1 = ResourcePool::Factory::Net::LDAP->new("hostname1");
my $f2 = ResourcePool::Factory::Net::LDAP->new("hostname1");
my $f3 = ResourcePool::Factory::Net::LDAP->new("hostname2");
my $f4 = ResourcePool::Factory::Net::LDAP->new("hostname2");
my $f5 = ResourcePool::Factory::Net::LDAP->new("hostname1");
ok(($f1 == $f2) && ($f1 == $f5) && ($f3 == $f4) && ($f1 != $f3));
} else { skip "skip Net::LDAP not found", 0; }

if (exists $INC{"Net/LDAP.pm"}) {
my $f1 = ResourcePool::Factory::Net::LDAP->new("hostname");
my $f2 = ResourcePool::Factory::Net::LDAP->new("hostname");
my $f3 = ResourcePool::Factory::Net::LDAP->new("hostname", [dn => 'dn', password => 'pass']);
my $f4 = ResourcePool::Factory::Net::LDAP->new("hostname", [dn => 'dn', password => 'pass']);
my $f5 = ResourcePool::Factory::Net::LDAP->new("hostname");
ok(($f1 == $f2) && ($f1 == $f5) && ($f3 == $f4) && ($f1 != $f3));
} else { skip "skip Net::LDAP not found", 0; }

if (exists $INC{"Net/LDAP.pm"}) {
my $f1 = ResourcePool::Factory::Net::LDAP->new("hostname", [dn => 'dn', password => 'pass1']);
my $f2 = ResourcePool::Factory::Net::LDAP->new("hostname", [dn => 'dn', password => 'pass1']);
my $f3 = ResourcePool::Factory::Net::LDAP->new("hostname", [dn => 'dn', password => 'pass2']);
my $f4 = ResourcePool::Factory::Net::LDAP->new("hostname", [dn => 'dn', password => 'pass2']);
my $f5 = ResourcePool::Factory::Net::LDAP->new("hostname", [dn => 'dn', password => 'pass1']);
ok(($f1 == $f2) && ($f1 == $f5) && ($f3 == $f4) && ($f1 != $f3));
} else { skip "skip Net::LDAP not found", 1; }

if (exists $INC{"Net/LDAP.pm"}) {
my $f1 = ResourcePool::Factory::Net::LDAP->new("hostname", [], [port => 10000]);
my $f2 = ResourcePool::Factory::Net::LDAP->new("hostname", [], [port => 10000]);
my $f3 = ResourcePool::Factory::Net::LDAP->new("hostname", [], [port => 20000]);
my $f4 = ResourcePool::Factory::Net::LDAP->new("hostname", [], [port => 20000]);
my $f5 = ResourcePool::Factory::Net::LDAP->new("hostname", [], [port => 10000]);
ok(($f1 == $f2) && ($f1 == $f5) && ($f3 == $f4) && ($f1 != $f3));
} else { skip "skip Net::LDAP not found",0; }
