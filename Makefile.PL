#*********************************************************************
#*** Makefile.PL
#*** Copyright (c) 2001 by Markus Winand <mws@fatalmind.com>
#*** $Id: Makefile.PL,v 1.2 2001/07/23 19:28:50 mws Exp $
#*********************************************************************

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'ResourcePool',
    'VERSION_FROM' => 'lib/ResourcePool.pm', # finds $VERSION
);
