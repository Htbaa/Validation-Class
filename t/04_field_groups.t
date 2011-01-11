#!perl -T
package Test::Validation;
use Test::More tests => 6;

BEGIN {
	use_ok( 'Validation::Class' );
}

field 'one' => {
	label => 'one',
	required => 1,
	min_length => 2,
	max_length => 3
};

field 'two' => {
	label => 'two',
	mixin_field => 'one'
};

# first group

field '1st:one' => {
	label => 'one',
	required => 1,
	min_length => 2,
	max_length => 3
};

field '1st:two' => {
	label => 'two',
	mixin_field => 'one'
};

# second group

field '2nd:one' => {
	label => 'one',
	required => 1,
	min_length => 2,
	max_length => 3
};

field '2nd:two' => {
	label => 'two',
	mixin_field => 'one'
};

my $i = undef;

# no params failure
eval { Test::Validation->new() };
ok(!$@, "no parameters non-failure");

# test standard setup
$i = Test::Validation->new({ 'one' => 'BB', 'two' => '22' });
ok($i->validate('one', 'two'), 'standard definition and validation passed');

# test first group setup
$i = Test::Validation->new({ 'one' => 'BB', 'two' => '22' });
ok($i->validate({ 'one' => '1st:one', 'two'=> '1st:two'}), '1st validation group passed');

# test second group setup
$i = Test::Validation->new({ 'one' => 'BB', 'two' => '22' });
ok($i->validate({ 'one' => '2nd:one', 'two'=> '2nd:two'}), '2nd validation group passed');

# test mixed group setup
$i = Test::Validation->new({ 'one' => 'BB', 'two' => '22' });
ok($i->validate({ 'one' => '2nd:one', 'two'=> '1st:two'}), 'mixed validation group passed');

1;