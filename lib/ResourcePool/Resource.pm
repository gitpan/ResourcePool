#*********************************************************************
#*** ResourcePool::Resource
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: Resource.pm,v 1.19 2002/10/06 13:43:21 mws Exp $
#*********************************************************************

package ResourcePool::Resource;

use strict;
use vars qw($VERSION);

$VERSION = "0.9909";

sub new($@) {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self = {};
	$self->{PlainResource} = {shift => $self};
	$self->{VALID} = 1;

        bless($self, $class);

        return $self;
}

sub close($) {
	my ($self) = @_;
	return undef;
}

sub fail_close($) {
	my ($self) = @_;
	warn "ResourcePool::Resource: closing failed Resource\n";
	return undef;
}

sub precheck($) {
	my ($self) = @_;
	return $self->{VALID};
}

sub postcheck($) {
	my ($self) = @_;
	return $self->{VALID};
}

sub get_plain_resource($) {
	my ($self) = @_;
	return $self->{PlainResource};
}

### ### Private part starts here

sub _my_very_private_and_secret_test_hook($$) {
	my ($self, $valid) = $_;
	$self->{VALID} = $valid;
}

1;
