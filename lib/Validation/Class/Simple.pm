# ABSTRACT: Simple Class for Ad-Hoc Validation

package Validation::Class::Simple;

use strict;
use warnings;

use Validation::Class ();
use Validation::Class::Core ('vc_prototypes');
use Validation::Class::Prototype;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Simple;

    # define object specific rules
    my $rules = Validation::Class::Simple->new(
        # define fields on-the-fly
        fields => {
            name  => { required => 1 },
            email => { required => 1 },
            pass  => { required => 1 },
            pass2 => { required => 1, matches => 'pass' },
        }
    );
    
    # set parameters to be validated
    $rules->params->add($parameters);

    # validate
    unless ($rules->validate) {
        # handle the failures
    }

=head1 DESCRIPTION

Validation::Class::Simple is simple validation module built around the powerful
L<Validation::Class> data validation framework.

This module is nothing more than a blank canvas; a clean validation class,
derived from L<Validation::Class>, which has not been pre-configured
(e.g. configured via keywords, etc). It can be useful in an environment where
you wouldn't care to create a validation class and instead would simply like to
pass rules to a validation engine in an ad-hoc fashion.

=head1 RATIONALE

If you are new to Validation::Class, or would like more information on the
underpinnings of this library and how it views and approaches data validation,
please review L<Validation::Class::WhitePaper::Validation>.

=head1 GUIDED TOUR

The instructions contained in this documentation are also relevant for
configuring any class derived from L<Validation::Class>. The validation logic
that follows is not specific to a particular use-case.

=head2 Parameter Handling

There are three ways to declare parameters you wish to have validated. The first
and most common approach is to supply the target parameters to the validation
class constructor:

    use Validation::Simple;

    my $rules = Validation::Simple->new(params => $parameters);

All input parameters are wrapped by the L<Validation::Class::Params> container
which provides generic functionality for managing hashes. Additionally you can
declare parameters by using the params object directly:

    use Validation::Simple;

    my $rules = Validation::Simple->new;

    $rules->params->clear;

    $rules->params->add(user => 'admin', pass => 's3cret');

    printf "%s parameters were submitted", $rules->params->count;

Finally, any parameter which has corresponding validation rules that has be
declared in a validation class derived from L<Validation::Class> will have an
accessor which can be used directly or as an argument to the constructor:

    package MyApp::Person;

    use Validation::Class;

    field 'name' => {
        required => 1
    };

    package main;

    my $rules = MyApp::Person->new(name => 'Egon Spangler');

    $rules->name('Egon Spengler');

=head2 Validation Rules



=head2 Flow Control (queuing, etc)



=head2 Error Handling



=head2 Input Filtering



=head2 Handling Failures (ignore_failure, etc)



=head2 Sharing Objects



=head2 Data Validation



=cut

sub new {

    my $class = shift;

    $class = ref $class || $class;

    my $self = bless {}, $class;

    vc_prototypes->add(
        "$self" => Validation::Class::Prototype->new(
            package => $class # inside-out prototype
        )
    );

    # let Validation::Class handle arg processing
    $self->Validation::Class::initialize_validator(@_);

    return $self;

}

{

    no strict 'refs';

    # inject prototype class aliases unless exist

    my @aliases = Validation::Class::Prototype->proxy_methods;

    foreach my $alias (@aliases) {

        *{$alias} = sub {

            my ($self, @args) = @_;

            $self->prototype->$alias(@args);

        };

    }

    # inject wrapped prototype class aliases unless exist

    my @wrapped_aliases = Validation::Class::Prototype->proxy_methods_wrapped;

    foreach my $alias (@wrapped_aliases) {

        *{$alias} = sub {

            my ($self, @args) = @_;

            $self->prototype->$alias($self, @args);

        };

    }

}

sub proto { goto &prototype } sub prototype {

    return vc_prototypes->get(shift);

}

sub DESTROY {

    return vc_prototypes->delete(shift);

}

1;
