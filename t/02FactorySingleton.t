#! /usr/bin/perl -w
#*********************************************************************
#*** t/02DBIFactorySingleton.t
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: 02FactorySingleton.t,v 1.9 2002/10/06 12:17:25 mws Exp $
#*********************************************************************
use strict;
use Test;

BEGIN{
	eval "use DBI;";
	eval "use Net::LDAP;"
};
BEGIN {	plan tests => 10;};


if (exists $INC{"DBI.pm"}) {
	require ResourcePool::Factory::DBI;
}
if (exists $INC{"Net/LDAP.pm"}) {
	require ResourcePool::Factory::Net::LDAP;
}

if (exists $INC{"DBI.pm"}) {
my $f1 = ResourcePool::Factory::DBI->new("DataSource1", "user", "pass");
my $f2 = ResourcePool::Factory::DBI->new("DataSource1", "user", "pass");
my $f3 = ResourcePool::Factory::DBI->new("DataSource2", "user", "pass");
my $f4 = ResourcePool::Factory::DBI->new("DataSource2", "user", "pass");
my $f5 = ResourcePool::Factory::DBI->new("DataSource1", "user", "pass");
ok(($f1->singleton() == $f2->singleton()) && ($f1->singleton() == $f5->singleton()) 
  && ($f3->singleton() == $f4->singleton()) && ($f1->singleton() != $f3->singleton()));
} else { skip "skip DBI not found",0; }

if (exists $INC{"DBI.pm"}) {
my $f1 = ResourcePool::Factory::DBI->new("DataSource", "user1", "pass");
my $f2 = ResourcePool::Factory::DBI->new("DataSource", "user1", "pass");
my $f3 = ResourcePool::Factory::DBI->new("DataSource", "user2", "pass");
my $f4 = ResourcePool::Factory::DBI->new("DataSource", "user2", "pass");
my $f5 = ResourcePool::Factory::DBI->new("DataSource", "user1", "pass");
ok(($f1->singleton() == $f2->singleton()) && ($f1->singleton() == $f5->singleton()) 
  && ($f3->singleton() == $f4->singleton()) && ($f1->singleton() != $f3->singleton()));
} else { skip "skip DBI not found",0; }

if (exists $INC{"DBI.pm"}) {
my $f1 = ResourcePool::Factory::DBI->new("DataSource", "user", "pass");
my $f2 = ResourcePool::Factory::DBI->new("DataSource", "user", "pass");
my $f3 = ResourcePool::Factory::DBI->new("DataSource", "user", "pass", {AutoCommit => 1});
my $f4 = ResourcePool::Factory::DBI->new("DataSource", "user", "pass", {AutoCommit => 1});
my $f5 = ResourcePool::Factory::DBI->new("DataSource", "user", "pass");
ok(($f1->singleton() == $f2->singleton()) && ($f1->singleton() == $f5->singleton()) 
  && ($f3->singleton() == $f4->singleton()) && ($f1->singleton() != $f3->singleton()));
} else { skip "skip DBI not found",0; }

if (exists $INC{"Net/LDAP.pm"}) {
my $f1 = ResourcePool::Factory::Net::LDAP->new("hostname1");
my $f2 = ResourcePool::Factory::Net::LDAP->new("hostname1");
my $f3 = ResourcePool::Factory::Net::LDAP->new("hostname2");
my $f4 = ResourcePool::Factory::Net::LDAP->new("hostname2");
my $f5 = ResourcePool::Factory::Net::LDAP->new("hostname1");
ok(($f1->singleton() == $f2->singleton()) && ($f1->singleton() == $f5->singleton()) 
  && ($f3->singleton() == $f4->singleton()) && ($f1->singleton() != $f3->singleton()));
} else { skip "skip Net::LDAP not found", 0; }

####### OLD Syntax checks start here (checking compatibility)
####### these tests are repeted with the new syntax below
if (exists $INC{"Net/LDAP.pm"}) {
my $f1 = ResourcePool::Factory::Net::LDAP->new("hostname");
my $f2 = ResourcePool::Factory::Net::LDAP->new("hostname");
my $f3 = ResourcePool::Factory::Net::LDAP->new("hostname", [dn => 'dn', password => 'pass']);
my $f4 = ResourcePool::Factory::Net::LDAP->new("hostname", [dn => 'dn', password => 'pass']);
my $f5 = ResourcePool::Factory::Net::LDAP->new("hostname");
ok(($f1->singleton() == $f2->singleton()) && ($f1->singleton() == $f5->singleton()) 
  && ($f3->singleton() == $f4->singleton()) && ($f1->singleton() != $f3->singleton()));
} else { skip "skip Net::LDAP not found", 0; }

if (exists $INC{"Net/LDAP.pm"}) {
my $f1 = ResourcePool::Factory::Net::LDAP->new("hostname", [dn => 'dn', password => 'pass1']);
my $f2 = ResourcePool::Factory::Net::LDAP->new("hostname", [dn => 'dn', password => 'pass1']);
my $f3 = ResourcePool::Factory::Net::LDAP->new("hostname", [dn => 'dn', password => 'pass2']);
my $f4 = ResourcePool::Factory::Net::LDAP->new("hostname", [dn => 'dn', password => 'pass2']);
my $f5 = ResourcePool::Factory::Net::LDAP->new("hostname", [dn => 'dn', password => 'pass1']);
ok(($f1->singleton() == $f2->singleton()) && ($f1->singleton() == $f5->singleton()) 
  && ($f3->singleton() == $f4->singleton()) && ($f1->singleton() != $f3->singleton()));
} else { skip "skip Net::LDAP not found", 1; }

if (exists $INC{"Net/LDAP.pm"}) {
my $f1 = ResourcePool::Factory::Net::LDAP->new("hostname", [], [port => 10000]);
my $f2 = ResourcePool::Factory::Net::LDAP->new("hostname", [], [port => 10000]);
my $f3 = ResourcePool::Factory::Net::LDAP->new("hostname", [], [port => 20000]);
my $f4 = ResourcePool::Factory::Net::LDAP->new("hostname", [], [port => 20000]);
my $f5 = ResourcePool::Factory::Net::LDAP->new("hostname", [], [port => 10000]);
ok(($f1->singleton() == $f2->singleton()) && ($f1->singleton() == $f5->singleton()) 
  && ($f3->singleton() == $f4->singleton()) && ($f1->singleton() != $f3->singleton()));
} else { skip "skip Net::LDAP not found",0; }

######### New Syntax tests starting here

if (exists $INC{"Net/LDAP.pm"}) {
my $f1 = ResourcePool::Factory::Net::LDAP->new("hostname_new");
my $f2 = ResourcePool::Factory::Net::LDAP->new("hostname_new");
my $f3 = ResourcePool::Factory::Net::LDAP->new("hostname_new");
$f3->bind(dn => 'dn', password => 'pass');
my $f4 = ResourcePool::Factory::Net::LDAP->new("hostname_new");
$f4->bind(dn => 'dn', password => 'pass');
my $f5 = ResourcePool::Factory::Net::LDAP->new("hostname_new");
ok(($f1->singleton() == $f2->singleton()) && ($f1->singleton() == $f5->singleton()) 
  && ($f3->singleton() == $f4->singleton()) && ($f1->singleton() != $f3->singleton()));
} else { skip "skip Net::LDAP not found", 0; }

if (exists $INC{"Net/LDAP.pm"}) {
my $f1 = ResourcePool::Factory::Net::LDAP->new("hostname_new");
$f1->bind(dn => 'dn', password => 'pass1');
my $f2 = ResourcePool::Factory::Net::LDAP->new("hostname_new");
$f2->bind(dn => 'dn', password => 'pass1');
my $f3 = ResourcePool::Factory::Net::LDAP->new("hostname_new");
$f3->bind(dn => 'dn', password => 'pass2');
my $f4 = ResourcePool::Factory::Net::LDAP->new("hostname_new");
$f4->bind(dn => 'dn', password => 'pass2');
my $f5 = ResourcePool::Factory::Net::LDAP->new("hostname_new");
$f5->bind(dn => 'dn', password => 'pass1');
ok(($f1->singleton() == $f2->singleton()) && ($f1->singleton() == $f5->singleton()) 
  && ($f3->singleton() == $f4->singleton()) && ($f1->singleton() != $f3->singleton()));
} else { skip "skip Net::LDAP not found", 1; }

if (exists $INC{"Net/LDAP.pm"}) {
my $f1 = ResourcePool::Factory::Net::LDAP->new("hostname_new", port => 10000);
my $f2 = ResourcePool::Factory::Net::LDAP->new("hostname_new", port => 10000);
my $f3 = ResourcePool::Factory::Net::LDAP->new("hostname_new", port => 20000);
my $f4 = ResourcePool::Factory::Net::LDAP->new("hostname_new", port => 20000);
my $f5 = ResourcePool::Factory::Net::LDAP->new("hostname_new", port => 10000);
ok(($f1->singleton() == $f2->singleton()) && ($f1->singleton() == $f5->singleton()) 
  && ($f3->singleton() == $f4->singleton()) && ($f1->singleton() != $f3->singleton()));
} else { skip "skip Net::LDAP not found",0; }
