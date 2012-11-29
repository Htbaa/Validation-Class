# Super Awesome Streaming HTML Form Field Rendering Utility

package Validation::Class::Plugin::FormFields::Streamer;

use strict;
use warnings;
use overload '""' => \&render, fallback => 1;

use Validation::Class::Core;
use HTML::Element;

# VERSION

has parent => undef;
has field  => undef;
has config => sub{{}};

sub input_to_html {

    my ($self) = @_;

    my $input = HTML::Element->new('input');

    my $field  = $self->field;
    my $config = $self->config;
    my $style  = $config->{style};

    my $attributes = $config->{attributes};

    $attributes->{value} = $field->value;

    if ($style eq 'html5') {
        $attributes->{required}   = "required" if $field->required;
        $attributes->{min_length} = $field->min_length if $field->min_length;
        $attributes->{max_length} = $field->max_length if $field->max_length;
    }

    while (my($key, $val) = each(%{$attributes})) {
        $input->attr($key, $val);
    }

    return $input->as_HTML;

}

sub new {

    my $class = shift;

    my $arguments = $class->build_args(@_);

    my $self = bless $arguments, $class;

    # set defaults
    $self->config({
        style => '',
        element => 'input',
        attributes => {
            type   => 'text',
            id     => $self->field->name,
            name   => $self->field->name,
        }
    });

    return $self;

}

sub render {

    my ($self) = @_;

    my $element = $self->config->{element};
    my $routine = "$element\_to_html";

    return $self->can($routine) ? $self->$routine : '';

}

sub style {

    my ($self, $style) = @_;

    my $field  = $self->field;
    my $config = $self->config;
    my $attributes = $self->config->{attributes};

    $config->{style} = $style;

    return $self;

}

1;
