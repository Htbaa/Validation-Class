# ABSTRACT: Alias Directive for Validation Class Field Definitions

package Validation::Class::Directive::Alias;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::Alias;

    my $directive = Validation::Class::Directive::Alias->new;

=head1 DESCRIPTION

Validation::Class::Directive::Alias is a core validation class field directive
that provides the ability to map arbitrary parameter names with a field's
parameter value.

=cut

has 'mixin' => 0;
has 'field' => 1;
has 'multi' => 0;

sub before_validation {

    my ($self, $proto, $field, $param) = @_;

    # create a map from aliases if applicable

    if (defined $field->{alias}) {

        my $name = $field->{name};

        my $aliases = isa_arrayref($field->{alias}) ?
            $field->{alias} : [$field->{alias}]
        ;

        foreach my $alias (@{$aliases}) {

            if ($self->params->has($alias)) {

                $self->params($name => $self->params->delete($alias));

                push @{$self->stash->{'validation.fields'}}, $name;

            }

        }

    }

}

1;
