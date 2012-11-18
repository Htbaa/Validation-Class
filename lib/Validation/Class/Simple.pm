# ABSTRACT: Simple Class for Ad-Hoc Validation

package Validation::Class::Simple;

use strict;
use warnings;

use Validation::Class ();
use Validation::Class::Core ('vc_prototypes');
use Validation::Class::Prototype;

our $_proto = Validation::Class->prototype(__PACKAGE__);

# VERSION

=head1 DESCRIPTION

Validation::Class::Simple is nothing more than a blank canvas; a validation
class derived from L<Validation::Class> which has not been pre-configured
(e.g. by using keywords, etc). It can be useful in an environment where you
wouldn't care to create a validation class and instead would simply like to pass
rules to a validation engine in an ad-hoc fashion.

=cut

sub new {

    my $class = shift;

    $class = ref $class || $class;

    my $self  = bless {},  $class;

    $self->initialize_validator(@_);

    return $self;

}

1;
