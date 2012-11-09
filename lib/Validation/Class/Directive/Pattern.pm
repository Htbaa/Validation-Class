# ABSTRACT: Pattern Directive for Validation Class Field Definitions

package Validation::Class::Directive::Pattern;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::Pattern;

    my $directive = Validation::Class::Directive::Pattern->new;

=head1 DESCRIPTION

Validation::Class::Directive::Pattern is a core validation class field directive
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

        # build the regex
        my $regex = $directive;

        unless ("Regexp" eq ref $regex) {

            $regex =~ s/([^#X ])/\\$1/g;
            $regex =~ s/#/\\d/g;
            $regex =~ s/X/[a-zA-Z]/g;
            $regex = qr/$regex/;

        }

        unless ( $value =~ $regex ) {

            my $handle = $field->{label} || $field->{name};

            my $error = "$handle does not match the "
                ."pattern $directive";

            $field->errors->add($field->{error} || $error);

            return 0;

        }

    }

    return 1;

}

1;
