# ABSTRACT: Toggle Directive for Validation Class Field Definitions

package Validation::Class::Directive::Toggle;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::Toggle;

    my $directive = Validation::Class::Directive::Toggle->new;

=head1 DESCRIPTION

Validation::Class::Directive::Toggle is a core validation class field directive
that provides the ability to toggle a field's `required` directive.

=cut

has 'mixin' => 0;
has 'field' => 1;
has 'multi' => 0;

1;
