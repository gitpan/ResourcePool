#*********************************************************************
#*** ResourcePool::Command
#*** Copyright (c) 2002-2005 by Markus Winand <mws@fatalmind.com>
#*** $Id: Command.pm,v 1.7.2.3 2005/01/05 19:43:34 mws Exp $
#*********************************************************************
package ResourcePool::Command;

use vars qw($VERSION);

$VERSION = "1.0104";

sub new($) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	return $self;
}

sub info($) {
	my ($self) = @_;
	return ref($self) . ": info has not been overloaded";
}

1;
