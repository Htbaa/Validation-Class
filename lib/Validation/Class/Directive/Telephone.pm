# ABSTRACT: Telephone Directive for Validation Class Field Definitions

package Validation::Class::Directive::Telephone;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 DESCRIPTION

Validation::Class::Directive::Telephone is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin'   => 1;
has 'field'   => 1;
has 'multi'   => 0;
has 'message' => '%s is not a valid telephone number';

sub validate {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{telephone}) {

        if (defined $param) {

            my $tre = qr/^(?:\+?1)?[-. ]?\(?[2-9][0-8][0-9]\)?[-. ]?[2-9][0-9]{2}[-. ]?[0-9]{4}$/;

            $self->error($proto, $field) unless $param =~ $tre;

        }

    }

    return $self;

}

1;
