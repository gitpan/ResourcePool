#*********************************************************************
#*** ResourcePool::Command
#*** Copyright (c) 2002,2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: Command.pm,v 1.12 2009-11-25 14:40:22 mws Exp $
#*********************************************************************
package ResourcePool::Command;

use vars qw($VERSION);

$VERSION = "1.0106";

sub new($) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	$self->resetReports();
	return $self;
}

sub init($) {
	my ($self) = @_;
}

sub preExecute($$) {
	my ($self, $res) = @_;
}

sub postExecute($$) {
	my ($self, $res) = @_;
}

sub cleanup($) {
	my ($self) = @_;
}

#sub revertExecute($$) {
#	my ($self, $res) = @_;
#}

sub _resetReports($) {
	my ($self) = @_;
	$self->{reports} = ();
}

sub _addReport($$) {
	my ($self, $rep) = @_;
	push(@{$self->{reports}}, $rep);
}

sub getReports($) {
	my ($self) = @_;
	return @{$self->{reports}};
}

sub info($) {
	my ($self) = @_;
	return ref($self) . ": info() has not been overloaded";
}

1;
