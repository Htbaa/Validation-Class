# ABSTRACT: Between Directive for Validation Class Field Definitions

package Validation::Class::Directive::Between;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::Between;

    my $directive = Validation::Class::Directive::Between->new;

=head1 DESCRIPTION

Validation::Class::Directive::Between is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin'     => 1;
has 'field'     => 1;
has 'multi'     => 1;
has 'validator' => \&_build_validator;

sub _build_validator {

    my ($directive, $value, $field, $class) = @_;

    my ($min, $max) = "ARRAY" eq ref $directive ?
        @{$directive} : split /(?:\s{1,})?[,\-]{1,}(?:\s{1,})?/, $directive;

    $min = scalar($min);
    $max = scalar($max);

    $value = length($value);

    if (defined $value) {

        unless ($value >= $min && $value <= $max) {

            my $handle = $field->{label} || $field->{name};
            my $error  = "$handle must contain between $directive characters";

            $field->errors->add($field->{error} || $error);

            return 0;

        }

    }

    return 1;

}

1;
