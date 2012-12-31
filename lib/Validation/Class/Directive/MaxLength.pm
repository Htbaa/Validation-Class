# ABSTRACT: MaxLength Directive for Validation Class Field Definitions

package Validation::Class::Directive::MaxLength;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            password => {
                max_length => 50
            }
        }
    );

    # set parameters to be validated
    $rules->params->add($parameters);

    # validate
    unless ($rules->validate) {
        # handle the failures
    }

=head1 DESCRIPTION

Validation::Class::Directive::MaxLength is a core validation class field
directive that validates the length of all characters in the associated
parameters.

=cut

has 'mixin'     => 1;
has 'field'     => 1;
has 'multi'     => 0;
has 'message'   => '%s must not contain more than %s characters';

sub validate {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    if (defined $field->{max_length} && defined $param) {

        my $max_length = $field->{max_length};

        if ( $field->{required} || $param ) {

            if (length($param) > $max_length) {

                $self->error(@_, $max_length);

            }

        }

    }

    return $self;

}

1;
