#! /usr/bin/perl -w
#*********************************************************************
#*** t/Singelton.pm
#*** Copyright (c) 2001 by Markus Winand <mws@fatalmind.com>
#*** $Id: Singelton.t,v 1.1 2001/10/07 18:30:55 mws Exp $
#*********************************************************************

use strict;
use Test;

BEGIN { plan tests => 11; };
use lib 't/';
use Count;

my $cnt = new Count(0);
ok(defined $cnt);
ok($cnt->next == 0);
ok($cnt->next == 1);

my $cnt2 = new Count(0);
ok (defined $cnt2);
ok ($cnt == $cnt2);
ok ($cnt2->next == 2);

my $cnt3 = new Count(1);
ok (defined $cnt3);
ok ($cnt3 != $cnt);
ok ($cnt3->next == 1);

ok ($cnt2->next == 3);
ok ($cnt->next == 4);

