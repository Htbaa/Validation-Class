# ABSTRACT: DependsOn Directive for Validation Class Field Definitions

package Validation::Class::Directive::DependsOn;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::DependsOn;

    my $directive = Validation::Class::Directive::DependsOn->new;

=head1 DESCRIPTION

Validation::Class::Directive::DependsOn is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin'     => 1;
has 'field'     => 1;
has 'multi'     => 1;
has 'validator' => \&_build_validator;

sub _build_validator {

    my ($directive, $value, $field, $class) = @_;

    if (defined $value) {

        my $dependents = "ARRAY" eq ref $directive ?
        $directive : [$directive];

        if (@{$dependents}) {

            my @blanks = ();

            foreach my $dep (@{$dependents}) {

                push @blanks,
                    $class->fields->{$dep}->{label} ||
                    $class->fields->{$dep}->{name}
                    if ! $class->param($dep);

            }

            if (@blanks) {

                my $handle = $field->{label} || $field->{name};

                my $error = "$handle requires " . join(", ", @blanks) .
                    " to have " . (@blanks > 1 ? "values" : "a value");

                $field->errors->add($field->{error} || $error);

                return 0;

            }

        }

    }

    return 1;

}

1;
