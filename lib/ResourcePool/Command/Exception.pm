#*********************************************************************
#*** ResourcePool::Command::Exception
#*** Copyright (c) 2002,2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: Exception.pm,v 1.1 2003/01/20 18:59:48 mws Exp $
#*********************************************************************
package ResourcePool::Command::Exception;

use vars qw($VERSION);
#use overload ('""' => 'stringify');

$VERSION = "1.0100";

sub new($$$$) {
	my $proto = shift;
	my $origexception = shift;
	my $command = shift;
	my $executions = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	$self->_setException($origexception);
	$self->_setCommand($command);
	$self->_setExecutions($executions);

	return $self;
}

sub _setCommand($$) {
	my ($self, $command) = @_;
	$self->{command} = $command;
}

sub getCommand($) {
	my ($self) = @_;
	return $self->{command};
}

sub _setExecutions($$) {
	my ($self, $executions) = @_;
	$self->{executions} = $executions;
}

sub getExecutions($$) {
	my ($self) = @_;
	return $self->{executions};
}

sub _setException($$) {
	my ($self, $exception) = @_;
	$self->{exception} = $exception;
}

sub getException($) {
	my ($self) = @_;
	return $self->{exception};
}

sub rootException($) {
	my ($self) = @_;
	my $rv = $self->{exception};
	eval {
		$rv = $rv->rootException();
	};
	if ($rv) {
		return $rv;
	} else {
		return $self->{exception};
	}
}

sub stringify($) {
	my ($self) = @_;
	my $class = ref($self) || $self;
	return $class . ': failed with "' 
		. $self->rootException()
		. '" while executing "'
		. $self->getCommand()
		. '"';
}

1;
