# ABSTRACT: Length Directive for Validation Class Field Definitions

package Validation::Class::Directive::Length;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::Length;

    my $directive = Validation::Class::Directive::Length->new;

=head1 DESCRIPTION

Validation::Class::Directive::Length is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin'     => 1;
has 'field'     => 1;
has 'multi'     => 0;
has 'validator' => \&_build_validator;

sub _build_validator {

    my ($directive, $value, $field, $class) = @_;

    $value = length($value);

    if (defined $value) {

        unless ($value == $directive) {

            my $handle = $field->{label} || $field->{name};
            my $characters = $directive > 1 ?
            "characters" : "character";

            my $error = "$handle must contain exactly " .
                "$directive $characters";

            $field->errors->add($field->{error} || $error);

            return 0;

        }

    }

    return 1;

}

1;
