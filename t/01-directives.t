#!perl -T
package Test::Validation;
use Test::More tests => 11;

BEGIN {
	use_ok( 'Validation::Class' );
}

field 'test1' => {
	required => 1,
};

field 'test2' => {
	mixin_field => 'test1',
	error => 'another value is always required'
};

field 'test3' => {
	regex => '^\d+$'
};

field 'test4' => {
	label => 'test4',
	required => 1,
	min_length => 2,
	max_length => 3
};

field 'test5' => {
	label => 'test5',
	ref_type => 'array'
};

# no params failure
eval { Test::Validation->new() };
ok(!$@, "no parameters non-failure");

# test required directive
my $tv = Test::Validation->new({ 'test1' => undef });
$tv->validate('test1');
ok($tv->errors('test1')->[0] eq 'parameter `test1` is required',
   "required field test");

# test error directive
$tv = Test::Validation->new({});
$tv->validate('test2');
ok(($tv->errors('test2')->[0]) eq 'another value is always required',
   "custom field error test");

# test regex directive
$tv = Test::Validation->new({ test3 => 'this' });
$tv->validate('test3');
ok(@{$tv->errors()}, "regex failure test");
$tv = Test::Validation->new({ test3 => 100 });
$tv->validate('test3');
ok(!@{$tv->errors()}, "regex success test");

# test min_length max_length
$tv = Test::Validation->new({ test4 => 47683463763864 });
$tv->validate('test4');
ok($tv->errors()->[0] eq "test4 cannot be greater than 3 characters",
   "maximum length test");
$tv = Test::Validation->new({ test4 => 1 });
$tv->validate('test4');
ok($tv->errors()->[0] eq "test4 must contain at least 2 characters",
   "minimum length test");

# test ref_type
$tv = Test::Validation->new({ test5 => 47683463763864 });
$tv->validate('test5'); 
ok($tv->errors()->[0] eq "test5 is not being stored as an array reference",
   "reference type failure test");
$tv = Test::Validation->new({ test5 => [1234, 5678] });
$tv->validate('test5');
ok(!@{$tv->errors()}, "reference type test");

# test no error count
$tv = Test::Validation->new({ test1 => 1 });
$tv->validate('test1');
ok(!@{$tv->errors()}, "error count test");

# warn(($tv->errors())[0]);

1;