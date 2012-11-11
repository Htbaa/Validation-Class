# ABSTRACT: Field Object for Validation::Class Classes

package Validation::Class::Field;

use Validation::Class::Errors;
use Validation::Class::Core;

use Carp 'confess';

# VERSION

use base 'Validation::Class::Mapping';

INIT {

    use Validation::Class::Configuration;

    my $conf = Validation::Class::Configuration->new;

    foreach my $directive ($conf->directives->values) {

        # create accessors from default configuration (once)

        if ($directive->field) {

            my $name = $directive->name;

            # errors object
            if ($name eq 'errors') {
                has $name => sub { Validation::Class::Errors->new };
            }

            # everything else
            else {
                has $name => sub { undef };
            }

        }

    }

}

=head1 DESCRIPTION

Validation::Class::Field provides functions for processing for field objects
and provides accessors for field directives. This class is derived from the
L<Validation::Class::Mapping> class.

=cut

sub new {

    my $class = shift;

    my $config = $class->build_args(@_);

    confess "Can't create a new field object without a name attribute"
        unless $config->{name}
    ;

    my $self = bless {}, $class;

    $self->add($config);

    return $self;

}

1;
