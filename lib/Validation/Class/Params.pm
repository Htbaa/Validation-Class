# ABSTRACT: Container Class for Data Input Parameters

package Validation::Class::Params;

use Validation::Class::Core '!has';
use Hash::Flatten ();
use Carp 'confess';

# VERSION

use base 'Validation::Class::Mapping';

use Validation::Class::Mapping;

=head1 DESCRIPTION

Validation::Class::Params is a container class for input parameters and is
derived from the L<Validation::Class::Mapping> class.

=cut

sub add {

    my $self = shift;

    my $arguments = $self->build_args(@_);

    while (my ($key, $value) = each %{$arguments}) {

        confess

            "A parameter value must be a string or an array of strings, all " .
            "other structures are illegal"

            unless ("ARRAY" eq (ref($value) || "ARRAY"))

        ;

        $self->{$key} = $value;

    }

    confess

        "Parameter values must be strings, arrays of strings, or hashrefs " .
        "whose values are any of the previously mentioned values, i.e. an " .
        "array with nested structures is illegal"

        if $self->flatten->grep(qr/(:.*:|:\d+.)/)->count

    ;

    return $self;

}

sub flatten {

    my ($self) = @_;

    return Validation::Class::Mapping->new(
        Hash::Flatten::flatten($self->hash)
    );

}

sub unflatten {

    my ($self) = @_;

    return Validation::Class::Mapping->new(
        Hash::Flatten::unflatten($self->hash)
    );

}

1;
