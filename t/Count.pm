#*********************************************************************
#*** t/Count.pm
#*** Copyright (c) 2001 by Markus Winand <mws@fatalmind.com>
#*** $Id: Count.pm,v 1.1 2001/10/07 18:30:55 mws Exp $
#*********************************************************************

package Count;

use ResourcePool::Singelton;
#push @ISA "Singelton";
push @Count::ISA ,qw(ResourcePool::Singelton);


sub new($$) {
	my $proto = shift;
        my $class = ref($proto) || $proto;
	my $self;

	$self = $class->SUPER::new(@_);
	if (!exists($self->{CNT})) {
		$self->{CNT} = $_[0];
		bless($self, $class);
	}
	
	return $self;
}

sub next($) {
	my ($self) = @_;
	return $self->{CNT}++;
}
1;
