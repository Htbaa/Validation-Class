# ABSTRACT: Container Class for Validation::Class::Field Objects

package Validation::Class::Fields;

use strict;
use warnings;

# VERSION

use Carp 'confess';

use base 'Validation::Class::Collection';

=head1 SYNOPSIS

    ...

=head1 DESCRIPTION

Validation::Class::Fields is a container class for L<Validation::Class::Field>
objects and is derrived from the L<Validation::Class::Collection> class.

=cut

sub clear {} #noop

1;