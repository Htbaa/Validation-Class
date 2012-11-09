# ABSTRACT: Errors Directive for Validation Class Field Definitions

package Validation::Class::Directive::Errors;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::Errors;

    my $directive = Validation::Class::Directive::Errors->new;

=head1 DESCRIPTION

Validation::Class::Directive::Errors is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin' => 0;
has 'field' => 1;
has 'multi' => 0;

1;
