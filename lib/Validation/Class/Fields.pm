# ABSTRACT: Container Class for Validation::Class::Field Objects

package Validation::Class::Fields;

use strict;
use warnings;

# VERSION

use Carp 'confess';

use base 'Validation::Class::Collection';

use Validation::Class::Field;

=head1 SYNOPSIS

    ...

=head1 DESCRIPTION

Validation::Class::Fields is a container class for L<Validation::Class::Field>
objects and is derived from the L<Validation::Class::Collection> class.

=cut

sub add {
    
    my $self = shift;
    
    my %arguments = @_ % 2 ? %{$_[0]} : @_;
    
    while (my($key, $object) = each %arguments) {
    
        $object->{name} = $key
            unless defined $object->{name};
        
        $object = Validation::Class::Field->new($object)
            unless "Validation::Class::Field" eq ref $object;
        
        $self->{$key} = $object;
    
    }
    
    return $self;
    
}

sub clear {} #noop

1;