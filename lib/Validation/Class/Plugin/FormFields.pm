# ABSTRACT: Validation::Class HTML Form Field Renderer

package Validation::Class::Plugin::FormFields;

use strict;
use warnings;

use Validation::Class::Plugin::FormFields::Streamer;
use Validation::Class::Core;

# VERSION

=head1 DESCRIPTION

Validation::Class::Plugin::FormFields is not an HTML form construction kit, nor
is it a one-size-fits-all form handling framework, it is however a plugin for
use with L<Validation::Class> which allows you to render HTML form fields based
on your defined validation fields and rules.

Why render fields individually and not the entire form? Form generation is a
heavily opinionated subject whereas the generating of HTML elements is alot less
bias and definately alot more straight-forward. Full-blown form generation locks
you in a box offering only slight convenience and major headaches when you need
anything more than the out-of-the-box generated output.

=cut

has prototype => undef;

sub new {

    my ($class, $prototype) = @_;

    my $self = { prototype => $prototype };

    $self->{fields}  = { map {$_ => undef} $prototype->fields->keys };
    $self->{streams} = { map {$_ => undef} $prototype->fields->keys };

    return bless $self, $class;

}

sub select {

    my ($self, $field) = @_;

    $field = $self->prototype->fields->get($field);

    return unless $field;

    return $self->{streams}->{$field->name} ||= do {
        Validation::Class::Plugin::FormFields::Streamer->new(
            field  => $field,
            parent => $self
        );
    }

}

1;
