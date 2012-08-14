# ABSTRACT: Container Class for Data Input Parameters

package Validation::Class::Params;

use strict;
use warnings;

# VERSION

use Carp 'confess';
use Hash::Flatten 'flatten', 'unflatten';

use base 'Validation::Class::Collection';

=head1 SYNOPSIS

    ...

=head1 DESCRIPTION

Validation::Class::Params is a container class for standard data input
parameters and is derived from the L<Validation::Class::Collection> class.

=cut

sub add {
    
    my $self = shift;
    
    my $arguments = @_ % 2 ? $_[0] : {@_};
    
    $arguments = flatten $arguments;
    
    confess
        
        "Parameter configuration not supported, a Validation::Class parameter ".
        "value must be a string or an arrayref of strings or nested hashrefs " . 
        "of the aforementioned"
        
        if grep /\:\d+./, keys %{$arguments}
        
    ;

    foreach my $code (sort keys %{$arguments}) {
        
        my ($key, $index) = $code =~ /(.*):(\d+)$/;
        
        if ($key && defined $index) {
            
            my $value = delete $arguments->{$code};
            
            $arguments->{$key} ||= [];
            $arguments->{$key}   = [] if "ARRAY" ne ref $arguments->{$key};
            
            $arguments->{$key}->[$index] = $value;
            
        }
        
    }
    
    while (my($key, $value) = each(%{$arguments})) {
        
        $key =~ s/[^\w\.]//g; # deceptively important, re: &flatten
        
        $self->{$key} = $value;
        
    }
    
    return $self;
    
}

1;
