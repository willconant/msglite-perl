package Msglite;

use warnings;
use strict;

use Msglite::Message;
use IO::Socket::INET;
use IO::Socket::UNIX;

=head1 NAME

Msglite

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Perl client library for Msglite (http://github.com/willconant/msglite)

    use Msglite;

    my $msglite = Msglite->at_unix_socket('/tmp/msglite.socket');
    
    $msglite->send("Hello!", 5, "myOwnAddress");
    
    my $msg = $msglite->ready(5, "myOwnAddress");
    print $msg->body, "\n";

=cut

use constant {
	READY_CMD     => '<',
	MESSAGE_CMD   => '>',
	QUERY_CMD     => '?',
	TIMEOUT_CMD   => '*',
	QUIT_CMD      => '.',
	ERROR_CMD     => '-',	
};

=head1 CONSTRUCTORS

=over

=item at_unix_socket

	my $msglite = Msglite->at_unix_socket('/tmp/msglite.socket');

Returns a Msglite client connected to the specified unix domain socket.

=cut

sub at_unix_socket {
	my ($class, $path) = @_;
	
	my $io_socket = IO::Socket::UNIX->new(
		Peer => $path,
		Type => SOCK_STREAM,
		Timeout => 1) || die $!;
		
	return bless {
		io_socket => $io_socket,
	}, $class;
}

=item at_tcp_socket

	my $msglite = Msglite->at_unix_socket('127.0.0.1:9813');

Returns a Msglite client connected to the specified TCP address.

=cut

sub at_tcp_socket {
	my ($class, $addr) = @_;
	
	my $io_socket = IO::Socket::INET->new($addr) || die $!;
		
	return bless {
		io_socket => $io_socket,
	}, $class;
}

=back

=head1 METHODS

=over

=item ready

	my $msg = $msglite->ready(TIMEOUT, ADDR1 [, ADDR2]..);
	my $msg = $msglite->ready(5, "addr1", "addr2");

Returns the next available message ready at one of the specified addresses.

If no message becomes available within the specified timeout, returns undef.

=cut

sub ready {
	my ($self, $timeout, @on_addrs) = @_;
	
	my $buf = join(' ', READY_CMD, $timeout, @on_addrs) . "\r\n";
	
	$self->_io_socket->print($buf)
		|| die "error writing to socket: $!";
		
	return $self->_read_message;
}

=item send

	$msglite->send(BODY, TIMEOUT, TO_ADDR [, REPLY_ADDR]);
	$msglite->send("hello", 5, "someAddr", "myReplyAddr");
	
Sends a message. Returns nothing.

=cut

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
	
	$self->_io_socket->print($buf)
		|| die "error writing to socket: $!";
}

=item query

	my $reply = $msglite->query(BODY, TIMEOUT, TO_ADDR);

Sends a message and then awaits a reply. If no reply becomes available
before TIMEOUT, returns undef.

=cut

sub query {
	my ($self, $body, $timeout, $to_addr) = @_;
	
	my $buf = join(' ', QUERY_CMD, length($body), $timeout, $to_addr) . "\r\n";
	
	if (length($body) > 0) {
		$buf .= $body . "\r\n";
	}
	
	$self->_io_socket->print($buf)
		|| die "error writing to socket: $!";
	
	return $self->_read_message;
}

=item quit

	$msglite->quit;

Finishes and closes the connection.

=cut

sub quit {
	my ($self) = @_;
	
	$self->_io_socket->print(QUIT_CMD . "\r\n");
	$self->_io_socket->close;
}

=back

=cut

sub _io_socket {
	$_[0]->{io_socket};
}

sub _read_message {
	my ($self) = @_;
	
	local $/ = "\r\n";
	
	my $cmd_line = $self->_io_socket->getline;
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
		$self->_io_socket->read($body, int($command[1]))
			|| die "error reading body of message: $!";
		
		$self->_io_socket->read(my $crlf, 2)
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

=head1 AUTHOR

Will Conant, C<< <will.conant at gmail.com> >>


=head1 SUPPORT AND DOCUMENTATION

This project is hosted at http://github.com/willconant/msglite-perl

Report bugs, find documentation, and submit patches there.


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010 William R. Conant, WillConant.com
Use of this source code is governed by the MIT licence:
http://www.opensource.org/licenses/mit-license.php


=cut

1;
