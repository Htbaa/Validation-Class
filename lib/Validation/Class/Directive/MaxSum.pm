# ABSTRACT: MaxSum Directive for Validation Class Field Definitions

package Validation::Class::Directive::MaxSum;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 DESCRIPTION

Validation::Class::Directive::MaxSum is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin'     => 1;
has 'field'     => 1;
has 'multi'     => 0;
has 'message'   => '%s cannot be greater then %s';

sub validate {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    if (defined $field->{max_sum} && defined $param) {

        my $max_sum = $field->{max_sum};

        if ( $field->{required} || $param ) {

            if (int($param) > int($max_sum)) {

                $self->error(@_, $max_sum);

            }

        }

    }

    return $self;

}

1;
