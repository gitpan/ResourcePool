#*********************************************************************
#*** ResourcePool::LoadBalancer::FallBack
#*** Copyright (c) 2002,2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: FallBack.pm,v 1.7.2.2 2003/05/07 19:40:13 mws Exp $
#*********************************************************************
package ResourcePool::LoadBalancer::FallBack;

use vars qw($VERSION @ISA);
use ResourcePool::LoadBalancer::FailBack;

$VERSION = "1.0103";
push @ISA, "ResourcePool::LoadBalancer::FailBack";

# just a synonym, nothing changes

1;
