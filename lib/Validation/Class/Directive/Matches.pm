# ABSTRACT: Matches Directive for Validation Class Field Definitions

package Validation::Class::Directive::Matches;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::Matches;

    my $directive = Validation::Class::Directive::Matches->new;

=head1 DESCRIPTION

Validation::Class::Directive::Matches is a core validation class field directive
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
        my $this = $value;
        my $that = $class->param($directive) || '';

        unless ( $this eq $that ) {

            my $handle  = $field->{label} || $field->{name};
            my $handle2 = $class->fields->{$directive}->{label}
                || $class->fields->{$directive}->{name};

            my $error = "$handle does not match $handle2";

            $field->errors->add($field->{error} || $error);

            return 0;

        }

    }

    return 1;

}

1;
