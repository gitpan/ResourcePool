#*********************************************************************
#*** ResourcePool::Command::NoFailoverException
#*** Copyright (c) 2002,2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: NoFailoverException.pm,v 1.2 2003/02/22 20:22:34 mws Exp $
#*********************************************************************
package ResourcePool::Command::NoFailoverException;

use strict;
use vars qw($VERSION);
use ResourcePool::Command::Exception;
$VERSION = "1.0100";

sub new($;$) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	$self->{exception} = shift;
	return $self;
}

sub rootException($) {
	my ($self) = @_;
	return ResourcePool::Command::Exception::rootException($self);
}

1;

