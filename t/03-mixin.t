use Test::More tests => 7;

# load module
BEGIN { use_ok( 'Validation::Class' ) }

my ($c, $x, $r) ;

$x = $c = {
    mixins => {
	'mixin1' => {
	    
	}
    },
    fields => {
	'test1',
	{
	    label      => 'test one',
	    error      => 'test1 invalid',
	    validation => sub {1},
	    mixin      => 'mixin1'
	},
	
	'test2',
	{
	    label       => 'test two',
	    mixin_field => 'test1'
	},
	
	'test3',
	{
	    label      => 'test three',
	    error      => 'invalid test3',
	    validation => sub { 1 },
	    mixin      => 'mixin1'
	},
	
	'test4',
	{
	    mixin       => 'mixin1',
	    mixin_field => 'test1',
	    mixin_field => 'test3'
	}
    },
    params => {
        foobar => 'apple'
    }
};

    $r = Validation::Class->new(%{$x});

# for now, the filters and errors directives gets added automatically
my  $others = 2;

ok  4 + $others == scalar(keys(%{$r->fields->{test1}})),
    'test1 directives count accurate';
ok  2 + $others == scalar(keys(%{$r->fields->{test2}})),
    'test2 directives count accurate';
ok  4 + $others == scalar(keys(%{$r->fields->{test3}})),
    'test3 directives count accurate';
ok  4 + $others == scalar(keys(%{$r->fields->{test3}})),
    'test4 directives count accurate';

$x->{fields}->{test2}->{filter} = [qw/trim strip/];

    $r = Validation::Class->new(%{$x});

ok  2 == @{$r->fields->{test2}->{filters}}, 'new filters count is correct';

$x->{mixins}->{mixin1}->{filters} = [qw/trim strip lowcase/];

    $r = Validation::Class->new(%{$x});

ok  3 == @{$r->fields->{test2}->{filters}}, 'merged filters count is correct';

#warn $r->errors->to_string();
