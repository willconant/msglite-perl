package Msglite::Client;

use Moose;

use Msglite::Message;
use IO::Socket::UNIX;

use constant {
	READY_CMD     => '<',
	MESSAGE_CMD   => '>',
	QUERY_CMD     => '?',
	TIMEOUT_CMD   => '*',
	QUIT_CMD      => '.',
	ERROR_CMD     => '-',	
};

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
	my ($self, $timeout, @on_addrs) = @_;
	
	my $buf = join(' ', READY_CMD, $timeout, @on_addrs) . "\r\n";
	
	$self->io_socket->print($buf)
		|| die "error writing to socket: $!";
		
	return $self->_read_message;
}

sub send {
	my ($self) = shift;
	
	my $msg;
	if (!ref($_[0])) {
		if (@_ < 3 || @_ > 4) {
			die "wrong number of arguments to send";
		}
		my $reply_addr = @_ == 4 ? $_[3] : '';
		$msg = Msglite::Message->new({
			body       => $_[0],
			timeout    => $_[1],
			to_addr    => $_[2],
			reply_addr => $reply_addr,
		});
	}
	else {
		$msg = $_[0];
	}
	
	my $buf = join(' ', MESSAGE_CMD, length($msg->body), $msg->timeout, $msg->to_addr, $msg->reply_addr) . "\r\n";
	
	if (length($msg->body) > 0) {
		$buf .= $msg->body . "\r\n";
	}
	
	$self->io_socket->print($buf)
		|| die "error writing to socket: $!";
}

sub query {
	my ($self, $body, $timeout, $to_addr) = @_;
	
	my $buf = join(' ', QUERY_CMD, length($body), $timeout, $to_addr) . "\r\n";
	
	if (length($body) > 0) {
		$buf .= $body . "\r\n";
	}
	
	$self->io_socket->print($buf)
		|| die "error writing to socket: $!";
	
	return $self->_read_message;
}

sub quit {
	my ($self) = @_;
	
	$self->io_socket->print(QUIT_CMD . "\r\n");
	$self->io_socket->close;
}

sub _read_message {
	my ($self) = @_;
	
	local $/ = "\r\n";
	
	my $cmd_line = $self->io_socket->getline;
	chomp $cmd_line;
	
	my @command = split /\s+/, $cmd_line;
	
	return undef if $command[0] eq TIMEOUT_CMD;
	
	die $cmd_line if $command[0] eq ERROR_CMD;
	die "unexpected line from msglite server: $cmd_line" if $command[0] ne MESSAGE_CMD;
	
	if (@command < 4 || @command > 5) {
		die "unexpected number of message params from msglite server: $cmd_line";
	}
	
	my $reply_addr = @command == 5 ? $command[4] : '';
	
	my $body = '';
	if ($command[1] > 0) {
		$self->io_socket->read($body, int($command[1]))
			|| die "error reading body of message: $!";
		
		$self->io_socket->read(my $crlf, 2)
			|| die "error reading body of message: $!";
			
		if ($crlf ne "\r\n") {
			die "expected \\r\\n from msglite server after message body";
		}
	}
	
	return Msglite::Message->new({
		body       => $body,
		timeout    => $command[2],
		to_addr    => $command[3],
		reply_addr => $reply_addr,
	})
}

no Moose;
__PACKAGE__->meta->make_immutable;
