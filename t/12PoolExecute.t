#! /usr/bin/perl -w
#*********************************************************************
#*** t/12PoolExecute.t
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: 12PoolExecute.t,v 1.4 2003/01/20 18:59:16 mws Exp $
#*********************************************************************
use strict;

use Test;
use ResourcePool;
use ResourcePool::Factory;
use ResourcePool::Command::NoFailoverException;
use ResourcePool::Command;

package MyTestCommandOK;

use vars qw(@ISA);
push @ISA, qw(ResourcePool::Command);

sub new($$) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);

	$self->setCalled(0);
	return $self;
}

sub execute($$) {
	my ($self, $resource) = @_;
	$self->setCalled($self->getCalled()+1);
	return 1;
}

# i start to like get/set methods for perl, because they enable
# compiletime checking of typos
sub setCalled($$) {
	my ($self, $val) = @_;
	$self->{called} = $val;
}

sub getCalled($) {
	my ($self) = @_;
	return $self->{called};
}

package MyTestCommandReturnFalse;

push @MyTestCommandReturnFalse::ISA, qw(MyTestCommandOK);

sub execute($$) {
	my ($self, @args) = @_;
	$self->SUPER::execute(@args);
	return 0;
}

package MyTestCommandReturnArgument;

push @MyTestCommandReturnArgument::ISA, qw(MyTestCommandOK);

sub execute($$$) {
	my ($self, $resource, $arg) = @_;
	$self->SUPER::execute($resource);
	return $arg;
}

package MyTestCommandDie;

push @MyTestCommandDie::ISA, qw(MyTestCommandOK);

sub execute($$) {
	my ($self, @args) = @_;
	$self->SUPER::execute(@args);
	die;
}

package MyTestCommandNoFailoverException;

push @MyTestCommandNoFailoverException::ISA, qw(MyTestCommandOK);

sub execute($$) {
	my ($self, @args) = @_;
	$self->SUPER::execute(@args);
	die ResourcePool::Command::NoFailoverException->new;
}

package FunkyException;

push @FunkyException::ISA, qw(ResourcePool::Command::NoFailoverException);

sub new($$) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	$self->{ex} = shift;
	return $self;
}

sub ex($) {
	my ($self) = @_;
	return $self->{ex};
}

package MyTestCommandFunkyException;

push @MyTestCommandFunkyException::ISA, qw(MyTestCommandOK);

sub execute($$) {
    my ($self, @args) = @_;
    $self->SUPER::execute(@args);
    die FunkyException->new('very funky');
}

package main;

BEGIN { plan tests => 17; };

# there shall be silence
$SIG{'__WARN__'} = sub {};


my $f1 = ResourcePool::Factory->new('f1');
my $p1 = ResourcePool->new($f1, MaxExecTry => 4);
my ($cmd, $rc);

$cmd = new MyTestCommandOK();
$rc = $p1->execute($cmd);
ok ($rc == 1);
ok ($cmd->getCalled() == 1);

$cmd = new MyTestCommandReturnFalse();
$rc = $p1->execute($cmd);
ok ($rc == 0);
ok ($cmd->getCalled() == 1);

$cmd = new MyTestCommandDie();
eval {
	$rc = $p1->execute($cmd);
};
ok ($@);
ok ($cmd->getCalled() == 4);

$cmd = new MyTestCommandNoFailoverException();
eval {
	$rc = $p1->execute($cmd);
};

ok ($@);
ok ($cmd->getCalled() == 1);

$cmd = new MyTestCommandFunkyException();
eval {
	$rc = $p1->execute($cmd);
};
ok ($@);
ok ($@->getException());
ok ($@->getException()->ex() eq 'very funky');
ok ($cmd->getCalled() == 1);


$cmd = new MyTestCommandReturnArgument();
$rc = $p1->execute($cmd, 'elch');
ok ($rc eq 'elch');
ok ($cmd->getCalled() == 1);

$rc = $p1->execute($cmd, 'hirsch');
ok ($rc eq 'hirsch');
ok ($cmd->getCalled() == 2);

$rc = ResourcePool::Command::Execute::execute($p1, $cmd, 'reh');
ok ($rc eq 'reh');
