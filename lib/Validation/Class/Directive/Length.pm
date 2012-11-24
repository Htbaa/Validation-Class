# ABSTRACT: Length Directive for Validation Class Field Definitions

package Validation::Class::Directive::Length;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 DESCRIPTION

Validation::Class::Directive::Length is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin'   => 1;
has 'field'   => 1;
has 'multi'   => 0;
has 'message' => '%s does not contain the correct number of characters';

sub validate {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    if (defined $field->{length} && defined $param) {

        my $length = $field->{length};

        if ($field->{required} || $param) {

            unless (length($param) == $length) {

                $self->error(@_);

            }

        }

    }

    return $self;

}

1;
