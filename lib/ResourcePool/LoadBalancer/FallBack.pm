#*********************************************************************
#*** ResourcePool::LoadBalancer::FallBack
#*** Copyright (c) 2002,2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: FallBack.pm,v 1.7.2.1 2003/03/27 20:18:40 mws Exp $
#*********************************************************************
package ResourcePool::LoadBalancer::FallBack;

use vars qw($VERSION @ISA);
use ResourcePool::LoadBalancer::FailBack;

$VERSION = "1.0102";
push @ISA, "ResourcePool::LoadBalancer::FailBack";

# just a synonym, nothing changes

1;
