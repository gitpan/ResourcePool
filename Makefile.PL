#*********************************************************************
#*** Makefile.PL
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: Makefile.PL,v 1.14 2002/10/12 17:24:58 mws Exp $
#*********************************************************************

use ExtUtils::MakeMaker qw(prompt WriteMakefile);
use Data::Dumper;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %opts;

$opts{NAME}	= 'ResourcePool',
$opts{VERSION} = '0.9910';

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{ABSTRACT} = 'A connection caching and pooling class.';
    $opts{AUTHOR} = 'Markus Winand <mws@fatalmind.com>';
}

if (0) { # interactive testing not finished yet
eval("use Net::LDAP;");
if (exists $INC{"Net/LDAP.pm"}) {
	printf("Great, you have Net::LDAP installed....\n\n");
	eval("use Net::LDAP::Constant qw(:all)");
	printf("If you have a ldap server which can be used for testing,\n");
	printf("please enter the data below, if not just press enter\n");
	my ($ldaph, $newparam);
	do {
		print("Hostname of your ldap server " .
			"(use 'host:port' to use non std. port)\n");
		$ldap_host = prompt("LDAP host:", "");
		if ($ldap_host ne "") {
			printf("Trying to connect via Net::LDAP....");
			my ($host, $port) = split(':', $ldap_host);
			if (defined $port) {
				$newparam = [$host, port => $port];
				print Dumper($newparam);
			} else {
				$newparam = [$host];
			}
			$ldaph = Net::LDAP->new(@{$newparam});
			if (defined $ldaph) {
				printf("looks good\n");
			} else {
				printf("failed\n\nYou can change the hostname or just ".
					"press enter to skipp testing\n");
			}
		}
	} while ($ldap_host ne "" && ! defined $ldaph);	
	if (defined $ldap_host && $ldap_host eq "") {
		undef $ldap_host;
	}
	printf("\n\n");
	if (defined $ldap_host) {
		printf("tying to anonymously bind against %s...", $ldap_host);
		my $rc = $ldaph->bind();
		if ($rc->code == LDAP_SUCCESS) {
			printf("looks good\n");
		} else {
			printf("failed\n");
		}
	}
	
	if (defined $ldap_host) {
		$Data::Dumper::Indent = 0;
		$Data::Dumper::Terse = 1;
		printf("Test configuration\n");	
		printf("==================\n");	
		printf("new() parameters: %s\n", Dumper($newparam));
	}
}

} # disabled
WriteMakefile(%opts);
