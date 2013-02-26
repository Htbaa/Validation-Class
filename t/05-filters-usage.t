use FindBin;
use Test::More;

use utf8;
use strict;
use warnings;

{

    package TestClass::FiltersUsage;

    use Validation::Class;

    filter 'flatten' => sub {
        $_[0] =~ s/[\t\r\n]+/ /g;
        return $_[0];
    };

    field 'biography' => {
        filters => ['trim', 'strip', 'flatten']
    };

    1;

    package main;

    my $biography = <<'TEXT';
    1. In arcu mi, sagittis vel pretium sit amet, tempor ac risus.
    2. Integer facilisis, ante ac tincidunt euismod, metus tortor.
    3. Suscipit erat, nec porta arcu urna eu nisl.
TEXT

    my $class = "TestClass::FiltersUsage";
    my $self  = $class->new(biography => $biography);

    ok $class eq ref $self, "$class instantiated";
    is_deeply $self->fields->biography->filters, ['trim', 'strip', 'flatten'], "$class has biography field with filters trim and flatten";
    ok $self->params->get('biography') =~ /^[^\n]+$/, "$class biography filter executed as expected";

}

done_testing;
