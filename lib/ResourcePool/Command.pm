#*********************************************************************
#*** ResourcePool::Command
#*** Copyright (c) 2002,2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: Command.pm,v 1.7.2.1 2003/03/27 20:35:58 mws Exp $
#*********************************************************************
package ResourcePool::Command;

use vars qw($VERSION);

$VERSION = "1.0102";

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
