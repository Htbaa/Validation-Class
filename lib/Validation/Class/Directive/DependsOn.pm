# ABSTRACT: DependsOn Directive for Validation Class Field Definitions

package Validation::Class::Directive::DependsOn;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::DependsOn;

    my $specification = Validation::Class::Directive::DependsOn->new;

=head1 DESCRIPTION

Validation::Class::Directive::DependsOn is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin'   => 1;
has 'field'   => 1;
has 'multi'   => 1;
has 'message' => '%s requires %s';

sub validate {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    if (defined $field->{depends_on}) {

        my $specification = $field->{depends_on};

        if ($field->{required} || $param) {

            my $dependents = isa_arrayref($specification) ?
                $specification : [$specification]
            ;

            if (@{$dependents}) {

                my @required_fields = ();

                foreach my $dependent (@{$dependents}) {

                    my $field = $proto->fields->get($dependent);

                    push @required_fields, $field->label || $field->name
                        unless $proto->params->has($dependent)
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
