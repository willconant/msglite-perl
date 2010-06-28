package Msglite::Message;

use strict;
use warnings;

=head1 CONSTRUCTORS

=over

=item new

	my $msg = Msglite::Message->new({
		body       => "hello",
		timeout    => 10,
		to_addr    => "someAddr",
		reply_addr => "someReplyAddr',
	});
	
=back

=cut

sub new {
	my ($class, $params) = @_;
	
	return bless {
		body       => $params->{body},
		timeout    => $params->{timeout},
		to_addr    => $params->{to_addr},
		reply_addr => $params->{reply_addr},
	}, $class;
}

=head1 METHODS

=over

=item body

Returns message body.

=cut

sub body {
	$_[0]->{body};
}

=item timeout

Returns message timeout.

=cut

sub timeout {
	$_[0]->{timeout};
}

=item to_addr

Returns message to_addr.

=cut

sub to_addr {
	$_[0]->{to_addr};
}

=item reply_addr

Returns message reply_addr.

=cut

sub reply_addr {
	$_[0]->{reply_addr};
}

=back

=cut

1;
