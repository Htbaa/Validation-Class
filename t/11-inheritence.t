use Test::More;

BEGIN {
    use FindBin;
    use lib $FindBin::Bin . "/myapp/lib";
}

package main;

use MyApp::Container;

my $v = MyApp::Container->new;

ok $v, 'new obj';
ok $v->proto->fields->{id},    'obj has an id field';
ok $v->proto->fields->{name},  'obj has a name field';
ok $v->proto->fields->{email}, 'obj has an email field';
ok $v->proto->mixins->{basic}, 'obj has a basic mixin';
ok $v->proto->mixins->{other}, 'obj has an other mixin';
ok $v->proto->mixins->{email}, 'obj has an email mixin';

ok 1 == $v->id, "obj's id field was set and is ok";
ok 'Boy' eq $v->name, "obj's name field was set and is ok";

done_testing;