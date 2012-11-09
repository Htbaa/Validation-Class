# ABSTRACT: Alias Directive for Validation Class Field Definitions

package Validation::Class::Directive::Alias;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::Alias;

    my $directive = Validation::Class::Directive::Alias->new;

=head1 DESCRIPTION

Validation::Class::Directive::Alias is a core validation class field directive
that provides the ability to map arbitrary parameter names with a field's
parameter value.

=cut

has 'mixin' => 0;
has 'field' => 1;
has 'multi' => 0;

1;
