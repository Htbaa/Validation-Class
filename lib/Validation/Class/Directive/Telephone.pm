# ABSTRACT: Telephone Directive for Validation Class Field Definitions

package Validation::Class::Directive::Telephone;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            user_phone => {
                telephone => 1
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

Validation::Class::Directive::Telephone is a core validation class field
directive that handles telephone number validation for the USA and North America.

=cut

has 'mixin'   => 1;
has 'field'   => 1;
has 'multi'   => 0;
has 'message' => '%s is not a valid telephone number';

sub validate {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{telephone} && defined $param) {

        if ($field->{required} || $param) {

            my $tre = qr/^(?:\+?1)?[-. ]?\(?[2-9][0-8][0-9]\)?[-. ]?[2-9][0-9]{2}[-. ]?[0-9]{4}$/;

            $self->error($proto, $field) unless $param =~ $tre;

        }

    }

    return $self;

}

1;
