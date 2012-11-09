# ABSTRACT: Container Class for Data Input Parameters

package Validation::Class::Params;

use Validation::Class::Core 'build_args';
use Hash::Flatten 'flatten', 'unflatten';
use Carp 'carp', 'confess';

# VERSION

use base 'Validation::Class::Mapping';

=head1 DESCRIPTION

Validation::Class::Params is a container class for input parameters and is
derived from the L<Validation::Class::Mapping> class.

=cut

sub add {

    my $self = shift;

    my $arguments = $self->build_args(@_);

    return $self unless my @keys = keys %{$arguments};

    $arguments = flatten $arguments;

    carp

        "Parameter values must be strings, arrays of strings, or hashrefs " .
        "whose values are any of the previously mentioned values"

        if grep /\:\d+./, keys @keys

    ;

    foreach my $code (sort @keys) {

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
