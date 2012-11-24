# Validation::Class Core Directives Collection

package Validation::Class::Directives;

use strict;
use warnings;

use base 'Validation::Class::Mapping';

use Validation::Class::Core '!has';

use Module::Find 'usesub';
use Carp 'confess';

our $_registry = {map{$_=>$_->new}(usesub 'Validation::Class::Directive')};

# VERSION

=pod DESCRIPTION

Validation::Class::Directives provides a collection of core Validation::Class
direcitves. This class inherits from L<Validation::Class::Mapping>.

=cut

sub new {

    my $class = shift;

    my $arguments = $class->build_args(@_);

    $arguments = $_registry unless keys %{$arguments};

    my $self = bless {}, $class;

    $self->add($arguments);

    return $self;

}


sub add {

    my $self = shift;

    my $arguments = $self->build_args(@_);

    while (my ($key, $value) = each %{$arguments}) {

        # never overwrite
        unless (defined $self->{$key}) {
            # is it a direct directive?
            if ("Validation::Class::Directive" eq ref $value) {
                $self->{$key} = $value;
            }
            # is it a directive sub-class
            elsif (isa_classref($value)) {
                if ($value->isa("Validation::Class::Directive")) {
                    $self->{$key} = $value;
                }
            }
            # is it a hashref
            elsif (isa_hashref($value)) {
                $self->{$key} = Validation::Class::Directive->new($value);
            }
        }

    }

    return $self;

}

sub resolve_dependencies {

    my ($self, $type) = @_;

    $type ||= 'validation';

    my $dependencies = {};

    foreach my $key ($self->keys) {

        my $class      = $self->get($key);
        my $name       = $class->name;
        my $dependents = $class->dependencies->{$type};

        # avoid invalid dependencies by excluding the unknown
        $dependencies->{$name} = [grep { $self->has($_) } @{$dependents}];

    }

    my @ordered;
    my %found;
    my %track;

    my @pending =  keys %$dependencies;
    my $limit   =  scalar(keys %$dependencies);
       $limit   += scalar(@{$_}) for values %$dependencies;

    while (@pending) {

        my $k = shift @pending;

        if (grep { $_ eq $k } @{$dependencies->{$k}}) {

            confess sprintf 'Direct circular dependency on event %s: %s -> %s',
            $type, $k, $k;

        }

        elsif (grep { ! exists $found{$_} } @{$dependencies->{$k}}) {

            confess sprintf 'Invalid dependency on event %s: %s -> %s',
            $type, $k, join(',', @{$dependencies->{$k}})
            if grep { ! exists $dependencies->{$_} } @{$dependencies->{$k}};

            confess
            sprintf 'Indirect circular dependency on event %s: %s -> %s ',
            $type, $k, join(',', @{$dependencies->{$k}})
            if $track{$k} && $track{$k} > $limit; # allowed circular iterations

            $track{$k}++ if push @pending, $k;

        }

        else {

            $found{$k} = 1;
            push @ordered, $k;

        }

    }

    my $charmap = join '', reverse @ordered;

    foreach my $el (keys %$dependencies) {

        for (@{$dependencies->{$el}}) {

            confess sprintf
            'Broken dependency chain; Faulty ordering on event %s: %s before %s',
            $type, $el, $_
            if index($charmap,$el) > index($charmap, $_);

        }

    }

    return (@ordered);

}

1;
