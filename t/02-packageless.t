#!perl -T
use Test::More tests => 2;

BEGIN {
	use_ok( 'Validation::Class' );
}

# use Validation::Class outside of a package
my $val = validation_schema(
	mixins => {
		'default' => {
			required => 1
		}
	},
	fields => {
		'test1' => {
			mixin => 'default'
		}
	},
);

$val = $val->new({ test1 => 1 }); $val->validate();
ok(!@{$val->errors}, 'packageless validation test');

1;