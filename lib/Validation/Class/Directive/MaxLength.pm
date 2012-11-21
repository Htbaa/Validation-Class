# ABSTRACT: MaxLength Directive for Validation Class Field Definitions

package Validation::Class::Directive::MaxLength;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::MaxLength;

    my $directive = Validation::Class::Directive::MaxLength->new;

=head1 DESCRIPTION

Validation::Class::Directive::MaxLength is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin'     => 1;
has 'field'     => 1;
has 'multi'     => 0;
has 'message'   => '%s must be %s or less characters';

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
