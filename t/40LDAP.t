#! /usr/bin/perl -w
#*********************************************************************
#*** t/30LDAP.t
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: 40LDAP.t,v 1.4 2002/07/09 07:35:32 mws Exp $
#*********************************************************************
use strict;

use Test;
BEGIN {
	use ResourcePool;
	eval "use Net::LDAP; use ResourcePool::Factory::Net::LDAP;";
	plan tests => 1;
}

if (!exists $INC{"Net/LDAP.pm"}) {
	skip("skip Net::LDAP not found", 0);
	exit(0);
}

# there shall be silence
$SIG{'__WARN__'} = sub {};

my $f1 = ResourcePool::Factory::Net::LDAP->new("hostname1");
my $pr1 = $f1->create_resource();
ok(! defined $pr1);
