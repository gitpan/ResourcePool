#*********************************************************************
#*** ResourcePool::LoadBalancer::FallBack
#*** Copyright (c) 2002-2005 by Markus Winand <mws@fatalmind.com>
#*** $Id: FallBack.pm,v 1.7.2.3 2005/01/05 19:43:36 mws Exp $
#*********************************************************************
package ResourcePool::LoadBalancer::FallBack;

use vars qw($VERSION @ISA);
use ResourcePool::LoadBalancer::FailBack;

$VERSION = "1.0104";
push @ISA, "ResourcePool::LoadBalancer::FailBack";

# just a synonym, nothing changes

1;
