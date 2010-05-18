package Msglite::Message;

use Moose;

has 'to_addr' => (
	is => 'ro',
	isa => 'Str',
);

has 'reply_addr' => (
	is => 'ro',
	isa => 'Str',
	default => '',
);

has 'timeout' => (
	is => 'ro',
	isa => 'Int',
);

has 'body' => (
	is => 'ro',
	isa => 'Str',
);

no Moose;
__PACKAGE__->meta->make_immutable;
