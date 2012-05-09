# ABSTRACT: Container Class for Relatives

package Validation::Class::Relatives;

use strict;
use warnings;

# VERSION

use Carp 'confess';

use base 'Validation::Class::Collection';

=head1 SYNOPSIS

    ...

=head1 DESCRIPTION

Validation::Class::Relatives is a container class for sub-classes registered via
the set/load function, this class is derived from the
L<Validation::Class::Collection> class.

=cut

1;