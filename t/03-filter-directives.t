#!perl -T

package Test::Validation;
use Test::More tests => 4;

BEGIN {
	use_ok( 'Validation::Class' );
}

mixin 'test' 	=> {
    required 	=> 15,
    min_length 	=> 1,
    max_length 	=> 1,
    filters 	=> [
	'trim',
	'titlecase'
    ]
};

field 'test0' 	=> {
    label 	=> 'some value',
    mixin 	=> 'test',
    validation 	=> sub {
        my ($o, $this, $params) = @_;
        my ($name, $value) = ($this->{label}, $this->{value});
        $o->error($this, "$name failed miserably and should never be $value...");
    }
};

field 'test1' 	=> {
    mixin_field => 'test0',
    filters 	=> [
	'strip',
	'trim'
    ]
};

field 'test2' 	=> {
    mixin_field => 'test1',
    filters 	=> [
	'strip',
	'trim',
	sub { $_[0] =~ s/123// }
    ]
};

my $test0 = Test::Validation->new({ test0 => ' this is a test    ' });
ok($test0->{params}->{test0} eq "This Is A Test", "trim test");

my $test1 = Test::Validation->new({ test1 => ' this is a test  1234567890  ' });
ok($test1->{params}->{test1} eq "This Is A Test 1234567890", "strip & trim test");

my $test2 = Test::Validation->new({ test2 => ' this is a test  1234567890  ' });
ok($test2->{params}->{test2} eq "This Is A Test 4567890", "custom regex test");

1;