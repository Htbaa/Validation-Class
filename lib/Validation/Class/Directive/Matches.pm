# ABSTRACT: Matches Directive for Validation Class Field Definitions

package Validation::Class::Directive::Matches;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 DESCRIPTION

Validation::Class::Directive::Matches is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin'   => 1;
has 'field'   => 1;
has 'multi'   => 1;
has 'message' => '%s does not match %s';

sub validate {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    if (defined $field->{matches}) {

        my $specification = $field->{matches};

        if (defined $param) {

            my $dependents = isa_arrayref($specification) ?
                $specification : [$specification]
            ;

            if (@{$dependents}) {

                my @required_fields = ();

                foreach my $dependent (@{$dependents}) {

                    $param ||= '';

                    my $field  = $proto->fields->get($dependent);
                    my $param2 = $proto->params->get($dependent) || '';

                    push @required_fields, $field->label || $field->name
                        unless $param eq $param2
                    ;

                }

                if (my @r = @required_fields) {

                    my$list=(join(' and ',join(', ',@r[0..$#r-1])||(),$r[-1]));

                    $self->error(@_, $list);

                }

            }

        }

    }

    return $self;

}

1;
