#!perl -T

use Test::More tests => 8;

BEGIN { use_ok( 'Msglite' ); }

SKIP: {

	if (! -e '/tmp/msglite.socket') {
		skip "no msglite server running at /tmp/msglite.socket", 7;
	}

	my $msglite = Msglite->at_unix_socket('/tmp/msglite.socket');
	
	$msglite->send("hello", 1, "msglite.clientTests");
	my $msg = $msglite->ready(1, "msglite.clientTests");
	ok(defined($msg) && ($msg->body eq 'hello'), 'send/receive');
	
	for (1..3) {
		$msglite->send("queued$_", 5, "msglite.clientTests");
	}
	
	for (1..3) {
		my $msg = $msglite->ready(1, "msglite.clientTests");
		ok(defined($msg) && ($msg->body eq "queued$_"), "queued $_");
	}
	
	my $timeout_msg = $msglite->ready(1, "msglite.clientTests");
	ok(!defined($timeout_msg), "ready timeout");
	
	$msglite->quit;
	
	my $child_pid = fork();
	if ($child_pid) {
		my $msglite = Msglite->at_unix_socket('/tmp/msglite.socket');
		my $msg = $msglite->ready(1, "msglite.clientTests");
		
		ok(defined($msg) && ($msg->body eq 'query_body'), 'query part 1');
		
		$msglite->send('reply_body', 1, $msg->reply_addr);
		$msg = $msglite->ready(1, "msglite.clientTests");
		
		ok(defined($msg) && ($msg->body eq 'reply_body_resent'), 'query part 2');
		
		$msglite->quit;
	}
	else {
		my $msglite = Msglite->at_unix_socket('/tmp/msglite.socket');
		my $msg = $msglite->query('query_body', 1, 'msglite.clientTests');
		$msglite->send($msg->body . '_resent', 1, 'msglite.clientTests');
		$msglite->quit;
		exit(0);
	}
}
