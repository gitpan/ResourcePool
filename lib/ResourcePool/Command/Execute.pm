#*********************************************************************
#*** ResourcePool::Command::Execute
#*** Copyright (c) 2002,2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: Execute.pm,v 1.4.2.1 2003/03/27 20:35:59 mws Exp $
#*********************************************************************
package ResourcePool::Command::Execute;

use ResourcePool::Command::Exception;
use vars qw($VERSION);
use Data::Dumper;

$VERSION = "1.0102";

sub execute($$@) {
	my ($self, $command, @addargs) = @_;
	my $try = $self->{MaxExecTry};
	my @rc = ();
	my $ex;

	do {
		my $plain_rec = $self->get();
		if (defined $plain_rec) {
			eval {
				@rc = $command->execute($plain_rec, @addargs);
			};
			$ex = $@;
			if ($ex) {
				if (ref($ex)) {
					if (isNoFailoverException($ex)) {
						warn('ResourcePool::Command->execute() failed: ' . Dumper($ex->rootException()));
					} else {
						warn('ResourcePool::Command->execute() failed: ' . Dumper($ex));
					}
				} else {
					warn('ResourcePool::Command->execute() failed: ' . $ex);
				}
			}
			if ($ex && !isNoFailoverException($ex)) {
				$self->fail($plain_rec);
			} else {
				$self->free($plain_rec);
			}
		}
	} while ($ex && ! isNoFailoverException($ex) && ($try-- > 0));
	if ($ex) {
		die ResourcePool::Command::Exception->new(
			  $ex
			, $command
			, ($self->{MaxExecTry} - $try) || 1
		);
	}
	if (wantarray) {
		return @rc;
	} else {
		return $rc[0];
	}
}

sub isNoFailoverException($) {
	my ($ex) = @_;
	my $rc;
	eval {
		$rc = $ex->isa('ResourcePool::Command::NoFailoverException');
	};
	if (! $@) {
		return $rc;	
	}
	return 0; # default, do failover
}

1;
