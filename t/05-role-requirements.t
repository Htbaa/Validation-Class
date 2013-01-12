use FindBin;
use Test::More;

use utf8;
use strict;
use warnings;

{

    package TestClass::Test1::RoleRequirements::Role::A;
    use Validation::Class;

    set required => 'awesome';

    package TestClass::Test1::RoleRequirements;
    use Validation::Class;

    eval { set role => 'TestClass::Test1::RoleRequirements::Role::A' };

    package main;

    ok(($@ and $@ =~ /missing method/), "role requirement failure");

}

{

    package TestClass::Test2::RoleRequirements::Role::A;
    use Validation::Class;

    set required => 'awesome';

    package TestClass::Test2::RoleRequirements;
    use Validation::Class;

    set role => 'TestClass::Test2::RoleRequirements::Role::A';

    sub awesome {1}

    package main;

    my $class = "TestClass::Test2::RoleRequirements";
    my $self  = $class->new;

    ok $class eq ref $self, "$class instantiated, role requirement successful";

}

done_testing;
