#*********************************************************************
#*** Makefile.PL
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: Makefile.PL,v 1.9.2.1 2002/08/30 16:25:05 mws Exp $
#*********************************************************************

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %opts;

$opts{NAME}	= 'ResourcePool',
$opts{VERSION} = '0.9907';

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{ABSTRACT} = 'A connection caching and pooling class.';
    $opts{AUTHOR} = 'Markus Winand <mws@fatalmind.com>';
}

WriteMakefile(%opts);
