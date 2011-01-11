#!perl -T
package Test::Validation;
use Test::More tests => 2;

BEGIN {
	use_ok( 'Validation::Class' );
}

mixin 'test' => {
    required => 15,
    min_length => 1,
    max_length => 1,
    regex => '^\d$'
};

field 'some_val' => {
    label => 'some value',
    mixin => 'test',
    validation => sub {
        my $this = $_[1];
	$_[0]->error($this, "$this->{label} failed miserably and should never be $this->{value}...")
	if $this->{value};
    }
};


# fix: NOT overwriting hash data
field 'other_data' => {
    mixin_field => 'some_val',
    label => 'other data',
    
};

my $tv = Test::Validation->new({ some_val => 'test', other_data => 'test' });
$tv->validate('some_val', 'other_data');
ok(@{$tv->errors} == 6, "miscellaneous tests - " . @{$tv->errors});

#use Data::Dumper qw/Dumper/;
#print Dumper($tv->{fields}->{other_data}), "\n";
#print Dumper($tv->{fields}->{some_val});

1;