#!perl -T

package Test::Validation;
use Test::More tests => 6;

BEGIN {
	use_ok( 'Validation::Class' );
}

mixin 'test'    => {
    required    => 1,
    min_length  => 1,
    max_length  => 1,
};

field '001'     => {
    mixin       => 'test',
    error       => 'this is a problem'
};

field '002'     => {
    mixin       => 'test',
};

# case: 1
my $v = Test::Validation->new();
ok(!$v->validate('001'), "case:1 validation successful");
my @errors = @{$v->errors};
ok(@errors, "case:1 input missing test");
ok($v->error('001')->[0] eq "this is a problem", "case:1 error msg test");

# case: 2
$v = Test::Validation->new({'002' => '1'});
ok($v->validate('002'), "case:2 validation successful");
my @errors = @{$v->errors};
ok(!@errors, "case:2 input missing test");

#print "# Error Output:\n";
#print join "\n", @{$v->errors};
1;