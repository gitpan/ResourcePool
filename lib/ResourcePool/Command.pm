#*********************************************************************
#*** ResourcePool::Command
#*** Copyright (c) 2002,2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: Command.pm,v 1.6 2003/01/20 18:59:16 mws Exp $
#*********************************************************************
package ResourcePool::Command;

use vars qw($VERSION);

$VERSION = "1.0100";

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
