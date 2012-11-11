# ABSTRACT: Container Class for Validation::Class::Field Objects

package Validation::Class::Fields;

use Validation::Class::Core 'build_args', '!has';
use Hash::Flatten ();
use Carp 'confess';

# VERSION

use base 'Validation::Class::Mapping';

use Validation::Class::Mapping;
use Validation::Class::Field;

=head1 DESCRIPTION

Validation::Class::Fields is a container class for L<Validation::Class::Field>
objects and is derived from the L<Validation::Class::Mapping> class.

=cut

sub add {

    my $self = shift;

    my $arguments = $self->build_args(@_);

    while (my ($key, $value) = each %{$arguments}) {

        # do not overwrite
        unless (defined $self->{$key}) {
            $self->{$key} = $value; # accept an object as a value
            $self->{$key} = Validation::Class::Field->new($value)
                unless "Validation::Class::Field" eq ref $self->{$key}
            ;
        }

    }

    confess

        "Illegal field names detected, possible attempt to define validation " .
        "rules for a parameter containing an array with nested structures"

        if $self->flatten->grep(qr/(:.*:|:\d+.)/)

    ;

    return $self;

}

sub flatten {

    my ($self) = @_;

    return Validation::Class::Mapping->new(
        Hash::Flatten::flatten($self->hash)
    );

}

1;
