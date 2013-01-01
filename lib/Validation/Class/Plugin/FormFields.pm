# ABSTRACT: Validation::Class HTML Form Field Renderer

package Validation::Class::Plugin::FormFields;

use strict;
use warnings;
use overload '""' => \&render, fallback => 1;

use Carp;

use Validation::Class::Util;
use HTML::Element;

# VERSION

=head1 SYNOPSIS

    # THIS PLUGIN IS UNTESTED !!!

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            username    => { required => 1 },
            password    => { required => 1 },
            remember_me => { required => 1, options => ['1|Remember Me?'] }
        }
    );

    my $fields = $rules->plugin('form_fields');

    print $fields->textbox('username');
    print $fields->textbox('password', type => 'password');
    print $fields->checkgroup('remember_me');

=head1 DESCRIPTION

Validation::Class::Plugin::FormFields is a plugin for L<Validation::Class>
which can leverage your validation class field definitions to render HTML form
elements. Please note that this plugin is intentionally lacking in
sophistication and try to take as few liberties as possible.

=head1 RATIONALE

Validation::Class::Plugin::FormFields is not an HTML form handler, nor is it an
HTML form builder, renderer, construction kit, or framework. Why render fields
individually and not the entire form? Form handling is a heavily opinionated
subject and this plugin reflects the following perspective.

HTML form generation, done literally, has too many contraints and considerations
to ever be truly ideal. Consider the following, it's been tried many many times
before, it's never pretty, too many conflicting contexts (css, js, security and
identification), css wants the form configured a certain way for styling
purposes, js wants the form configured a certain way for introspection purposes,
the app wants the form configured a certain way for processing purposes, etc.

So why do we continue to try? HTML forms are like werewolves and developers love
silver bullets, but bullets are actually made out of lead, not silver. So how do
you kill werewolves with lead? Hint, not by shooting them obviously.

I'd argue that we never really wanted complete form rendering anyway, what we
actually wanted was a simple way to reduce the tedium and repetitiveness that
comes with creating HTML form elements and handling submission and validation
of the associated data. We keep getting it wrong because we keep trying to build
on top of the same misconceptions.

So maybe we should backup a bit and try something different. The generating of
HTML elements is alot less constrained and definately much more straight-forward.

=cut

sub new {

    my $class     = shift;
    my $prototype = shift;

    my $self = {
        target    => '',
        elements  => {},
        prototype => $prototype
    };

    return bless $self, $class;

}

sub checkbox {

    my ($self, $name, %attributes) = @_;

    $self->{target} = $name;

    $attributes{type} ||= 'check';

    $self->declare('checkbox', $name, %attributes);

    return $self;

}

sub checkgroup {

    my ($self, $name, %attributes) = @_;

    $self->{target} = $name;

    $attributes{type} = 'check';

    $self->declare('checkgroup', $name, %attributes);

    return $self;

}

sub declare {

    my ($self, $method, $name, %attributes) = @_;

    my $proto = $self->{prototype};

    exit croak q(Can't declare new element without a field and type),
        unless $name && $method
    ;

    exit croak sprintf q(Can't locate field "%s" for use with element "%s"),
        $name, $method unless $proto->fields->has($name)
    ;

    my $field   = $proto->fields->get($name);

    $attributes{id}   ||= $field->name;
    $attributes{name} ||= $field->name;

    # handle value conditions
    my $value;

    if (defined $attributes{value}) {
        $value = $attributes{value};
    }

    elsif ($proto->params->has($name)) {
        $value = $proto->params->get($name);
    }

    else {
        $value = $field->value || $field->default;
    }

    my $processor = "_declare_$method";

    $self->$processor($field, $value, %attributes) if $self->can($processor);

    return $self;

}

sub _declare_checkbox {

    my ($self, $field, $value, %attributes) = @_;

    my $name = $field->name;

    my $element = HTML::Element->new('input');

    # set value attribute
    $value = isa_arrayref($value) ? $value->[0] : $value;
    $attributes{value} = $value;

    # set basic attributes
    while (my($key, $val) = each(%attributes)) {
        $element->attr($key, $val);
    }

    return $self->{elements}->{$name} = $element;

}

sub _declare_checkgroup {

    my ($self, $field, $value, %attributes) = @_;

    my $name = $field->name;

    my @elements;

    # set value attribute
    $value = isa_arrayref($value) ? $value->[0] : $value;
    $attributes{value} = $value;

    my @opts = grep defined, @{$field->options};
    my %vals = ();

    %vals = map {$_=>$_} isa_arrayref($value) ? @{$value}:($value) if $value;

    foreach my $opt (@opts) {

        my ($v, $c);

        if ($opt =~ /^([^\|]+)?\|(.*)/) {
            ($v, $c) = $opt =~ /^([^\|]+)?\|(.*)/;
        }
        elsif (isa_arrayref($opt)) {
            ($v, $c) = @{$opt};
        }
        else {
            ($v, $c) = ($opt, $opt);
        }

        my $element = HTML::Element->new('input');

        # set basic attributes
        while (my($key, $val) = each(%attributes)) {
            $element->attr($key, $val);
        }

        $element->attr(value => $v);
        $element->push_content(HTML::Element->new('span', _content => [$c]));
        $element->attr(checked => 'checked') if defined $vals{$v};

        push @elements, $element;

    }

    return $self->{elements}->{$name} = \@elements if @elements;

}

sub _declare_hidden {

    my ($self, $field, $value, %attributes) = @_;

    my $name = $field->name;

    my $element = HTML::Element->new('input');

    # set value attribute
    $value = isa_arrayref($value) ? $value->[0] : $value;
    $attributes{value} = $value;

    # set basic attributes
    while (my($key, $val) = each(%attributes)) {
        $element->attr($key, $val);
    }

    return $self->{elements}->{$name} = $element;

}

sub _declare_selectbox {

    my ($self, $field, $value, %attributes) = @_;

    my $name = $field->name;

    my @elements;

    my $element = HTML::Element->new('select');

    # set basic attributes
    while (my($key, $val) = each(%attributes)) {
        $element->attr($key, $val);
    }

    # set value attribute
    $value = isa_arrayref($value) ? $value->[0] : $value;
    $attributes{value} = $value;

    my @opts = grep defined, @{$field->options};
    my %vals = ();

    %vals = map {$_=>$_} isa_arrayref($value) ? @{$value}:($value) if $value;

    foreach my $opt (@opts) {

        my ($v, $c);

        if ($opt =~ /^([^\|]+)?\|(.*)/) {
            ($v, $c) = $opt =~ /^([^\|]+)?\|(.*)/;
        }
        elsif (isa_arrayref($opt)) {
            ($v, $c) = @{$opt};
        }
        else {
            ($v, $c) = ($opt, $opt);
        }

        my $option = HTML::Element->new('option');

        $option->attr(value => $v);
        $option->push_content($c);
        $option->attr(selected => 'selected') if defined $vals{$v};

        $element->push_content($option);

    }

    return $self->{elements}->{$name} = $element;

}

sub _declare_radiogroup {

    my ($self, $field, $value, %attributes) = @_;

    my $name = $field->name;

    my @elements;

    # set value attribute
    $value = isa_arrayref($value) ? $value->[0] : $value;
    $attributes{value} = $value;

    my @opts = grep defined, @{$field->options};
    my %vals = ();

    %vals = map {$_=>$_} isa_arrayref($value) ? @{$value}:($value) if $value;

    foreach my $opt (@opts) {

        my ($v, $c);

        if ($opt =~ /^([^\|]+)?\|(.*)/) {
            ($v, $c) = $opt =~ /^([^\|]+)?\|(.*)/;
        }
        elsif (isa_arrayref($opt)) {
            ($v, $c) = @{$opt};
        }
        else {
            ($v, $c) = ($opt, $opt);
        }

        my $element = HTML::Element->new('input');

        # set basic attributes
        while (my($key, $val) = each(%attributes)) {
            $element->attr($key, $val);
        }

        $element->attr(value => $v);
        $element->push_content(HTML::Element->new('span', _content => [$c]));
        $element->attr(checked => 'checked') if defined $vals{$v};

        push @elements, $element;

    }

    return $self->{elements}->{$name} = \@elements if @elements;

}

sub _declare_textarea {

    my ($self, $field, $value, %attributes) = @_;

    my $name = $field->name;

    my $element = HTML::Element->new('textarea');

    # set value attribute
    $value = isa_arrayref($value) ? $value->[0] : $value;
    $element->push_content($value);

    # set basic attributes
    while (my($key, $val) = each(%attributes)) {
        $element->attr($key, $val);
    }

    return $self->{elements}->{$name} = $element;

}

sub _declare_textbox {

    my ($self, $field, $value, %attributes) = @_;

    my $name = $field->name;

    my $element = HTML::Element->new('input');

    # set value attribute
    $value = isa_arrayref($value) ? $value->[0] : $value;
    $attributes{value} = $value;

    # set basic attributes
    while (my($key, $val) = each(%attributes)) {
        $element->attr($key, $val);
    }

    return $self->{elements}->{$name} = $element;

}

sub element {

    my ($self) = @_;

    return $self->{elements}->{$self->{target}};

}

sub hidden {

    my ($self, $name, %attributes) = @_;

    $self->{target} = $name;

    $attributes{type} ||= 'hidden';

    $self->declare('hidden', $name, %attributes);

    return $self;

}

sub multiselect {

    my ($self, $name, %attributes) = @_;

    $self->{target} = $name;

    $attributes{multiple} = 'yes';

    $self->selectbox($name, %attributes);

    return $self;

}

sub password {

    my ($self, $name, %attributes) = @_;

    $attributes{type} = 'password';

    $self->textbox($name, %attributes);

    return $self;

}

sub radiogroup {

    my ($self, $name, %attributes) = @_;

    $self->{target} = $name;

    $attributes{type} = 'radio';

    $self->declare('radiogroup', $name, %attributes);

    return $self;

}

sub selectbox {

    my ($self, $name, %attributes) = @_;

    $self->{target} = $name;

    $self->declare('selectbox', $name, %attributes);

    return $self;

}

sub textarea {

    my ($self, $name, %attributes) = @_;

    $self->{target} = $name;

    $self->declare('textarea', $name, %attributes);

    return $self;

}

sub textbox {

    my ($self, $name, %attributes) = @_;

    $self->{target} = $name;

    $attributes{type} ||= 'text';

    $self->declare('textbox', $name, %attributes);

    return $self;

}

sub render {

    my ($self)  = @_;

    my $element = $self->element;

    return isa_arrayref($element) ?
        join "\n", map { $_->as_HTML } @{$element} :
        $element->as_HTML
    ;

}

sub render_inner {

    my ($self)  = @_;

    my @pairs;
    my %attrs = $self->element->all_attr;

    my $type = delete $attrs{_tag};

    for (keys %attrs) {
        delete $attrs{$_} if /^_/;
    }

    my @attrs = %attrs;

    push @pairs, sprintf('%s="%s"', splice(@attrs, 0, 2)) while @attrs;

    return $type . ' ' . join ' ', @pairs;

}

1;
