# ABSTRACT: Configuration Class for Validation Classes

package Validation::Class::Configuration;

use Validation::Class::Listing;
use Validation::Class::Mapping;
use Validation::Class::Fields;
use Validation::Class::Mixins;
use Validation::Class::Core;

use Module::Find 'usesub';

our $_directives = [usesub 'Validation::Class::Directive'];

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Configuration;

    my $conf = Validation::Class::Configuration->new;

=head1 DESCRIPTION

Validation::Class::Configuration provides a configuration profile in form of a
singleton which is inherited by derived validation classes. This class inherits
from L<Validation::Class::Base>.

=cut

sub attributes {

    my ($self) = @_;

    return $self->profile->{ATTRIBUTES};

}

sub builders {

    my ($self) = @_;

    return $self->profile->{BUILDERS};

}

sub configure_profile {

    my ($self) = @_;

    $self->configure_profile_register_directives;
    $self->configure_profile_register_filters;
    $self->configure_profile_register_events;

    return $self;

}

sub configure_profile_register_directives {

    my ($self) = @_;

    # automatically attach discovered directive classes

    foreach my $class (@{$_directives}) {

        my $object = $class->new;
        my $name   = $object->name;

        $self->directives->add($name => $object);

    }

    return $self;

}

sub configure_profile_register_filters {

    my ($self) = @_;

    # automatically attach filters registered on in the filters directive

    my $directives = $self->directives;

    my $filters = $directives->get('filters');

    return unless $filters;

    $self->filters->add($filters->defaults);

    return $self;

}

sub configure_profile_register_events {

    my ($self) = @_;

    # inspect the directives for event subscriptions

    if (my @directives = ($self->directives->values)) {

        my $events = {
            # hookable events list, keyed by directive name
            'on_after_validation'   => {},
            'on_before_validation'  => {},
            'on_normalize'          => {},
            'on_validate'           => {}
        };

        while (my($name, $container) = each(%{$events})) {

            ($name) = $name =~ /^on_(\w+)/;

            foreach my $directive (@directives) {
                next if defined $container->{$name};
                if (my $routine = $directive->can($name)) {
                    $container->{$directive->name} = $routine;
                }
            }

        }

        $self->events->add($events);

    }

    return $self;

}

sub default_profile {

    return Validation::Class::Mapping->new({

        ATTRIBUTES  => Validation::Class::Mapping->new,

        BUILDERS    => Validation::Class::Listing->new,

        DIRECTIVES  => Validation::Class::Mapping->new,

        EVENTS     => Validation::Class::Mapping->new,

        FIELDS     => Validation::Class::Fields->new,

        FILTERS    => Validation::Class::Mapping->new,

        METHODS    => Validation::Class::Mapping->new,

        MIXINS     => Validation::Class::Mixins->new,

        PLUGINS    => Validation::Class::Mapping->new,

        PROFILES   => Validation::Class::Mapping->new,

        RELATIVES  => Validation::Class::Mapping->new,

    });

}

sub directives {

    my ($self) = @_;

    return $self->profile->{DIRECTIVES};

}

sub events {

    my ($self) = @_;

    return $self->profile->{EVENTS};

}

sub fields {

    my ($self) = @_;

    return $self->profile->{FIELDS};

}

sub filters {

    my ($self) = @_;

    return $self->profile->{FILTERS};

}

sub methods {

    my ($self) = @_;

    return $self->profile->{METHODS};

}

sub mixins {

    my ($self) = @_;

    return $self->profile->{MIXINS};

}

sub new {

    my $self = bless {}, shift;

    $self->configure_profile;

    return $self;

}

sub profile {

    my ($self) = @_;

    return $self->{profile} ||= $self->default_profile;

}

sub profiles {

    my ($self) = @_;

    return $self->profile->{PROFILES};

}

sub relatives {

    my ($self) = @_;

    return $self->profile->{RELATIVES};

}

1;
