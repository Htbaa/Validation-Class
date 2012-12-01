# ABSTRACT: Length Directive for Validation Class Field Definitions

package Validation::Class::Directive::Length;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

# VERSION

=head1 DESCRIPTION

Validation::Class::Directive::Length is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin'   => 1;
has 'field'   => 1;
has 'multi'   => 0;
has 'message' => '%s should be exactly %s characters';

sub validate {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    if (defined $field->{length} && defined $param) {

        my $length = $field->{length};

        if ($field->{required} || $param) {

            unless (length($param) == $length) {

                $self->error(@_, $length);

            }

        }

    }

    return $self;

}

1;
