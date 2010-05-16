package Msglite::Client;

use Moose;
use MooseX::SemiAffordanceAccessor;

use Msglite::Message;
use IO::Socket::UNIX;

has 'io_socket' => (
	is => 'ro',
);

sub at_unix_socket {
	my ($class, $path) = @_;
	
	my $io_socket = IO::Socket::UNIX->new(
		Peer => $path,
		Type => SOCK_STREAM,
		Timeout => 1) || die $!;
	
	return $class->new({io_socket => $io_socket});
}

sub ready {
	my ($self, $on_addr, $timeout) = @_;
	
	$self->io_socket->print("READY\non $on_addr\ntimeout $timeout\n\n")
		|| die "error writing to socket: $!";
		
	return $self->_read_message;
}

sub query {
	my ($self, $to_addr, $timeout, $body) = @_;
	
	my $buf = "QUERY\nto $to_addr\ntimeout $timeout\nbody " . length($body) . "\n\n$body\n";
	
	$self->io_socket->print($buf)
		|| die "error writing to socket: $!";
	
	return $self->_read_message;
}

sub send {
	my ($self, $msg) = @_;
	
	my $buf = "MESSAGE\n";
	$buf .= "to " . $msg->to_addr . "\n";
	
	if ($msg->reply_addr ne '') {
		$buf .= "reply " . $msg->reply_addr . "\n";
	}
	
	$buf .= "timeout " . $msg->timeout . "\n";
	
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
	
	die "missing body header" if !exists($headers{body});
	die "invalid format for body header" if $headers{body} !~ m/^\d+$/;
	
	my $body = '';
	if ($headers{body} > 0) {
		$self->io_socket->read($body, int($headers{body}))
			|| die "error reading body of message: $!";
	}
	
	$self->io_socket->read(my $nl, 1)
		|| die "error reading body of message: $!";
		
	die "body must be followed by newline" if $nl ne "\n";
	
	return Msglite::Message->new({
		to_addr    => $headers{to},
		reply_addr => "$headers{reply}",
		timeout    => $headers{timeout},
		body       => $body,
	})
}

1;
