package Msglite::Client;

use Moose;
use MooseX::SemiAffordanceAccessor;

use Msglite::Message;

has 'io_socket' => (
	is => 'ro',
);

sub ready {
	my ($self, $on_addr) = @_;
	
	$self->io_socket->print("READY\non $on_addr\n\n")
		|| die "error writing to socket: $!";
		
	return $self->_read_message;
}

sub send_query {
	my ($self, $to_addr, $body) = @_;
	
	my $buf = "QUERY\nto $to_addr\nbody " . length($body) . "\n\n$body\n";
	
	$self->io_socket->print($buf)
		|| die "error writing to socket: $!";
	
	return $self->_read_message;
}

sub send_message {
	my ($self, $msg) = @_;
	
	my $buf = "MESSAGE\n";
	$buf .= "to " . $msg->to_addr . "\n";
	
	if ($msg->reply_addr ne '') {
		$buf .= "reply " . $msg->reply_addr . "\n";
	}
	
	if ($msg->broadcast) {
		$buf .= "bcast 1\n";
	}
	
	$buf .= "body " . length($msg->body) . "\n\n";
	
	$buf .= $msg->body . "\n";
	
	$self->io_socket->print($buf)
		|| die "error writing to socket: $!";
}

sub quit {
	my ($self) = @_;
	
	$self->io_socket->print("QUIT\n\n");
	$self->io_socket->close;
}

sub _read_message {
	my ($self) = @_;
	
	local $/ = "\n";
	
	my $cmd_line = $self->io_socket->getline;
	die "unexpected line from msglite server" if ($cmd_line ne "MESSAGE\n");
	
	my %headers = (
		reply => '',
		bcast => '0',
	);
	
	for (;;) {
		my $header_line = $self->io_socket->getline;
		chomp($header_line);
		last if $header_line eq '';
		
		my ($k, $v) = split(/ /, $header_line, 2);
		$headers{$k} = $v;
	}
	
	die "invalid format for body header" if ($headers{body} == 0);
	
	$self->io_socket->read(my $body, int($headers{body}))
		|| die "error reading body of message: $!";
	
	$self->io_socket->read(my $nl, 1)
		|| die "error reading body of message: $!";
		
	die "body must be followed by newline" if $nl ne "\n";
	
	return Msglite::Message->new({
		to_addr    => $headers{to},
		reply_addr => "$headers{reply}",
		broadcast  => $headers{bcast} eq '1',
		body       => $body,
	})
}

1;