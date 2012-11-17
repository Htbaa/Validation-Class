# ABSTRACT: Field Object for Validation::Class Classes

package Validation::Class::Field;

use Validation::Class::Directives;
use Validation::Class::Errors;

use Validation::Class::Core '!has';
use Carp 'confess';

# VERSION

use base 'Validation::Class::Mapping';

my $directives = Validation::Class::Directives->new;

foreach my $directive ($directives->values) {

    # create accessors from default configuration (once)

    if ($directive->field) {

        my $name = $directive->name;

        next if __PACKAGE__->can($name);

        # errors object
        if ($name eq 'errors') {
            my %spec =
                ($name => sub { Validation::Class::Errors->new });
                Validation::Class::Core::has(%spec);
        }

        # everything else
        else {
            my %spec =
                ($name => sub { undef });
                Validation::Class::Core::has(%spec);
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

    confess "Cannot create a new field object without a name attribute"
        unless $config->{name}
    ;

    my $self = bless {}, $class;

    $self->add($config);

    return $self;

}

1;
