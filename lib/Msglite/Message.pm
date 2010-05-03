package Msglite::Message;

use Moose;
use MooseX::SemiAffordanceAccessor;

has 'to_addr' => (
	is => 'ro',
	isa => 'Str',
);

has 'reply_addr' => (
	is => 'ro',
	isa => 'Str',
	default => '',
);

has 'broadcast' => (
	is => 'ro',
	isa => 'Bool',
	default => '0',
);

has 'body' => (
	is => 'ro',
	isa => 'Str',
);

no Moose;
__PACKAGE__->meta->make_immutable;
