#*********************************************************************
#*** ResourcePool::Resource::DBI
#*** Copyright (c) 2001 by Markus Winand <mws@fatalmind.com>
#*** $Id: DBI.pm,v 1.6 2001/10/10 21:07:57 mws Exp $
#*********************************************************************

package ResourcePool::Resource::DBI;

use vars qw($VERSION @ISA);
use strict;
use DBI;
use ResourcePool::Resource;

$VERSION = "0.9903";
push @ISA, "ResourcePool::Resource";

sub new($$$$$) {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self = {};
        my $ds   = shift;
        my $user = shift;
        my $auth = shift;
        my $attr = shift;

	$self->{dbh} = DBI->connect($ds, $user, $auth, $attr);
	if (! defined $self->{dbh}) {
		warn "ResourcePool::Resource::DBI: Connect to '$ds' failed: $DBI::errstr\n";
		return undef;
	}
        bless($self, $class);

        return $self;
}

sub close($) {
	my ($self) = @_;
	$self->{dbh}->disconnect();
}

sub precheck($) {
	my ($self) = @_;	
	my $rc = $self->{dbh}->ping();

	if (!$rc) {
		$self->close();
	}
	return $rc;
}

sub get_plain_resource($) {
	my ($self) = @_;
	return $self->{dbh};
}

sub DESTROY($) {
	my ($self) = @_;
	$self->close();
}

1;


__END__

