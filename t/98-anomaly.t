use Test::More tests => 5;

use strict;
use warnings;

use Validation::Class;
use base 'Validation::Class';

my $params = {
     _dc => '0123456789'
};

my $v = Validation::Class->new(
    fields => {
	status => {
	    required   => 1,
	    error      => 'Invalid account status. Use Active/Inactive.',
	    filters    => [ 'trim', 'strip', 'alpha' ],
	    options    => 'Active, Inactive'
	}
    },
    params => {
	_dc => '0123456789'
    },
    ignore_unknown => 1
);

# params set at new function
ok $v->validate(keys %{$params}), 'validation ok';
ok $v->validate(keys %{$params}), 'validation ok';
ok $v->validate(keys %{$params}), 'validation ok';
ok $v->validate(keys %{$params}), 'validation ok';
ok $v->validate(keys %{$params}), 'validation ok';