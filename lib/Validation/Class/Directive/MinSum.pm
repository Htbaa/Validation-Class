# ABSTRACT: MinSum Directive for Validation Class Field Definitions

package Validation::Class::Directive::MinSum;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::MinSum;

    my $directive = Validation::Class::Directive::MinSum->new;

=head1 DESCRIPTION

Validation::Class::Directive::MinSum is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin'     => 1;
has 'field'     => 1;
has 'multi'     => 0;
has 'message'   => '%s must be greater than %s';

sub validate {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    if (defined $field->{min_sum} && defined $param) {

        my $min_sum = $field->{min_sum};

        if ( $field->{required} || $param ) {

            if (int($param) < int($min_sum)) {

                $self->error(@_, $min_sum);

            }

        }

    }

    return $self;

}

1;
