# ABSTRACT: Error Handling Object for Fields and Classes

package Validation::Class::Errors;

use Validation::Class::Core 'build_args';

# VERSION

use base 'Validation::Class::Listing';

=head1 DESCRIPTION

Validation::Class::Errors is responsible for error handling in Validation::Class
derived classes on both the class and field levels respectively and is derived
from the L<Validation::Class::Listing> class.

=cut

sub add {

    my ($self, @arguments) = @_;

    return unless @arguments;

    push @{$self}, @arguments;

    @{$self} = ($self->unique);

    return $self;

}

sub to_string {

    my ($self, $delimiter, $transformer) = @_;

    $delimiter = ', ' unless defined $delimiter; # default is a comma-space

    $self->each($transformer) if $transformer;

    return $self->join($delimiter);

}

1;
