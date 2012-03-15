use Test::More tests => 7;

BEGIN {
    use FindBin;
    use lib $FindBin::Bin . "/modules";
}

package MyVal;

use Validation::Class;

__PACKAGE__->load_classes;
__PACKAGE__->load_plugins('+MyVal::Plugin::Glade');

package ValMy;

use Validation::Class;

package ValMy::Alt;

use Validation::Class;

__PACKAGE__->load_plugins('+MyVal::Plugin::Glade');

package main;

my $v = MyVal->new( params => { foo => 1 } );

ok $v, 'initialization successful';

ok 'abc' eq $v->squash, 'glade plugin applied squash method to base';

eval { $v->stash->{smell}->() && $v->stash->{squirt}->() };
ok ! $@, 'glade plugin applied to base';

my $p = $v->class('person');

eval { $p->stash->{smell}->() && $p->stash->{squirt}->() };
ok !$@, 'glade plugin applied to person';
   
$v = ValMy->new( params => { foo => 1 } );

ok $v, 'initialization successful';

ok ! do { defined $v->stash->{smell} && defined $v->stash->{squirt} },
    'glade plugin not applied to base';

$p = ValMy::Alt->new( params => { foo => 1 } );

eval { $p->stash->{smell}->() && $p->stash->{squirt}->() };
ok ! $@, 'glade plugin applied to person';