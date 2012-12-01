# ABSTRACT: Time Directive for Validation Class Field Definitions

package Validation::Class::Directive::Time;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 DESCRIPTION

Validation::Class::Directive::Time is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin'   => 1;
has 'field'   => 1;
has 'multi'   => 0;
has 'message' => '%s requires a valid time';

sub validate {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{time}) {

        if (defined $param) {

            # determines if the param is a valid time
            # validates time as 24hr (HH:MM) or am/pm ([H]H:MM[a|p]m)
            # does not validate seconds

            my $tre = qr%^((0?[1-9]|1[012])(:[0-5]\d){0,2} ?([AP]M|[ap]m))$|^([01]\d|2[0-3])(:[0-5]\d){0,2}$%;

            $self->error($proto, $field) unless $param =~ $tre;

        }

    }

    return $self;

}

1;
