# ABSTRACT: MinSum Directive for Validation Class Field Definitions

package Validation::Class::Directive::MinSum;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::MinSum;

    my $directive = Validation::Class::Directive::MinSum->new;

=head1 DESCRIPTION

Validation::Class::Directive::MinSum is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin'     => 1;
has 'field'     => 1;
has 'multi'     => 0;
has 'validator' => \&_build_validator;

sub _build_validator {

    my ( $directive, $value, $field, $class ) = @_;

    if (defined $value) {

        unless ( $value >= $directive ) {

            my $handle = $field->{label} || $field->{name};
            my $error = "$handle can't be less than "
            ."$directive";

            $field->errors->add($field->{error} || $error);

            return 0;

        }

    }

    return 1;

}

1;
