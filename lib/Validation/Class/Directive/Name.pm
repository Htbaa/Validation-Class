# ABSTRACT: Name Directive for Validation Class Field Definitions

package Validation::Class::Directive::Name;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::Name;

    my $directive = Validation::Class::Directive::Name->new;

=head1 DESCRIPTION

Validation::Class::Directive::Name is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin' => 1;
has 'field' => 1;
has 'multi' => 0;

1;