# Input Validation Error Handling

use strict;
use warnings;

package Validation::Class::Errors;

# VERSION

use Moose::Role;

# class errors store
has 'errors' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] }
);

# return the number of errors
sub error_count {
    
    return scalar(@{shift->errors}); 
}

# return arrayref of class errors as a string
sub errors_to_string {
    my ($self, $delimiter, $transformer) = @_;
    
    $delimiter ||= ', '; # default delimiter is a comma
    
    return join $delimiter, map {
        
        # maybe? tranforms each error
        "CODE" eq ref $transformer ? $transformer->($_) : $_
    }   @{$self->errors};
}

no Moose::Role;

1;