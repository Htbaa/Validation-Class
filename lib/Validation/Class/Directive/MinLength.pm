# ABSTRACT: MinLength Directive for Validation Class Field Definitions

package Validation::Class::Directive::MinLength;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::MinLength;

    my $directive = Validation::Class::Directive::MinLength->new;

=head1 DESCRIPTION

Validation::Class::Directive::MinLength is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin'     => 1;
has 'field'     => 1;
has 'multi'     => 0;
has 'message'   => '%s must be %s or more characters';

sub validate {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    if (defined $field->{min_length} && defined $param) {

        my $min_length = $field->{min_length};

        if ( $field->{required} || $param ) {

            if (length($param) < $min_length) {

                $self->error(@_, $min_length);

            }

        }

    }

    return $self;

}

1;
