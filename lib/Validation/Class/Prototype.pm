# ABSTRACT: Data Validation Engine for Validation::Class Classes

package Validation::Class::Prototype;

use strict;
use warnings;

use Validation::Class::Configuration;
use Validation::Class::Directives;
use Validation::Class::Listing;
use Validation::Class::Mapping;
use Validation::Class::Params;
use Validation::Class::Fields;
use Validation::Class::Errors;
use Validation::Class::Core;

# VERSION

use Hash::Flatten 'flatten', 'unflatten';
use Module::Runtime 'use_module';
use Module::Find 'findallmod';
use List::MoreUtils 'uniq';
use Class::Forward 'clsf';
use Hash::Merge 'merge';
use Carp 'confess';

my $_registry = Validation::Class::Mapping->new; # prototype registry

=attribute attributes

The attributes attribute provides access to simple attributes registered on the
the calling class. This attribute is a L<Validation::Class::Mapping> object
containing hashref objects and CANNOT be overridden.

=cut

hold 'attributes' => sub { Validation::Class::Mapping->new };

=attribute builders

The builders attribute provides access to coderefs registered to hook into the
instantiation process of the calling class. This attribute is a
L<Validation::Class::Listing> object containing coderef objects and CANNOT be
overridden.

=cut

hold 'builders' => sub { Validation::Class::Listing->new };

=attribute configuration

The configuration attribute provides the default configuration profile.
This attribute is a L<Validation::Class::Configuration> object and CANNOT be
overridden.

=cut

hold 'configuration' => sub { Validation::Class::Configuration->new };

=attribute errors

The errors attribute provides access to class-level error messages.
This attribute is a L<Validation::Class::Errors> object, may contain
error messages and CANNOT be overridden.

=cut

hold 'directives' => sub { Validation::Class::Mapping->new };

=attribute directives

The directives attribute provides access to defined directive objects.
This attribute is a L<Validation::Class::Mapping> object containing
hashrefs and CANNOT be overridden.

=cut

hold 'errors' => sub { Validation::Class::Errors->new };

=attribute events

The events attribute provides access to validation events and the directives
that subscribe to them. This attribute is a L<Validation::Class::Mapping> object
and CANNOT be overridden.

=cut

hold 'events' => sub { Validation::Class::Mapping->new };

=attribute fields

The fields attribute provides access to defined fields objects.
This attribute is a L<Validation::Class::Fields> object containing
L<Validation::Class::Field> objects and CANNOT be overridden.

=cut

hold 'fields' => sub { Validation::Class::Fields->new };

=attribute filtering

The filtering attribute (by default set to 'pre') controls when incoming data
is filtered. Setting this attribute to 'post' will defer filtering until after
validation occurs which allows any errors messages to report errors based on the
unaltered data. Alternatively, setting the filtering attribute to '' or undef
will bypass all filtering unless explicitly defined at the field-level.

=cut

has 'filtering' => 'pre';

=attribute filters

The filters attribute provides access to defined filters objects.
This attribute is a L<Validation::Class::Mapping> object containing
code references and CANNOT be overridden.

=cut

hold 'filters' => sub { Validation::Class::Mapping->new };

=attribute ignore_failure

The ignore_failure boolean determines whether your application will live or die
upon failing to validate a self-validating method defined using the method
keyword. This is on (1) by default, method validation failures will set errors
and can be determined by checking the error stack using one of the error message
methods. If turned off, the application will die and confess on failure.

=cut

has 'ignore_failure' => '1';

=attribute ignore_unknown

The ignore_unknown boolean determines whether your application will live or
die upon encountering unregistered field directives during validation. This is
off (0) by default, attempts to validate unknown fields WILL cause the program
to die.

=cut

has 'ignore_unknown' => '0';

=attribute methods

The methods attribute provides access to self-validating code references.
This attribute is a L<Validation::Class::Mapping> object containing
code references.

=cut

hold 'methods' => sub { Validation::Class::Mapping->new };

=attribute mixins

The mixins attribute provides access to field templates.
This attribute is a L<Validation::Class::Mapping> object and CANNOT be
overridden.

=cut

hold 'mixins' => sub { Validation::Class::Mixins->new };

=pod package

The package attribute contains the namespace of the instance object currently
using this module.

=cut

hold 'package' => sub{ undef };

=attribute params

The params attribute provides access to input parameters.
This attribute is a L<Validation::Class::Mapping> object and CANNOT be
overridden.

=cut

hold 'params' => sub { Validation::Class::Params->new };

=attribute plugins

The plugins attribute provides access to loaded plugins.
This attribute is a L<Validation::Class::Params> object containing
plugin package names.

=cut

has plugins => sub { Validation::Class::Mapping->new };

=attribute profiles

The profiles attribute provides access to validation profile.
This attribute is a L<Validation::Class::Mapping> object containing
hash references and CANNOT be overridden.

=cut

hold 'profiles' => sub { Validation::Class::Mapping->new };

=attribute queued

The queued attribute returns an arrayref of field names for (auto) validation.
It represents a list of field names stored to be used in validation later. If
the queued attribute contains a list, you can omit arguments to the validate
method.

=cut

has 'queued' => sub { Validation::Class::Listing->new };

=attribute relatives

The relatives attribute provides access to loaded class relatives (child-classes).
This attribute is a L<Validation::Class::Mapping> object containing
package names and CANNOT be overridden.

=cut

hold 'relatives' => sub { Validation::Class::Mapping->new };

=attribute report_failure

The report_failure boolean determines whether your application will report
self-validating method failures as class-level errors. This is off (0) by default,
if turned on, an error messages will be generated and set at the class-level
specifying the method which failed in addition to the existing messages.

=cut

has 'report_failure' => 0;

=attribute report_unknown

The report_unknown boolean determines whether your application will report
unregistered fields as class-level errors upon encountering unregistered field
directives during validation. This is off (0) by default, attempts to validate
unknown fields will NOT be registered as class-level variables.

=cut

has 'report_unknown' => 0;

=attribute validated

The validated boolean simply denotes whether the validation routine has been
executed since the last normalization process (which occurs at instantiation
and before validation). Note, this is NOT an indicator of whether validation
has passed or failed.

=cut

has 'validated' => 0;

=pod stashed

The stashed attribute is a general purpose hash object.

=cut

has 'stashed' => sub { Validation::Class::Mapping->new };

=pod new

The object constructor

=cut

sub new {

    my $class = shift;

    my $arguments = $class->build_args(@_);

    confess
        "The $class class must be instantiated with a parameter named package ".
        "whose value is the name of the associated package" unless defined
        $arguments->{package} && $arguments->{package} =~ /\w/
    ;

    my $self = bless $arguments, $class;

    $_registry->add($arguments->{package}, $self);

    return $self;

}

sub apply_filter {

    my ($self, $filter, $field) = @_;

    my $name = $field;

    $field  = $self->fields->get($field);
    $filter = $self->filters->get($filter);

    return unless $field && $filter;

    if ($self->params->has($name)) {

        if (isa_coderef($filter)) {

            if (my $value = $self->params->get($name)) {

                if (isa_arrayref($value)) {

                    foreach my $el (@{$value}) {

                        $el = $filter->($el);

                    }

                }
                else {

                    $value = $filter->($value);

                }

                $self->params->add($name, $value);

            }

        }

    }

    return $self;

}

=method apply_filters

The apply_filters method (usually called automatically based on the filtering
attribute) can be used to run the currently defined parameters through the
filters defined in their matching fields.

    $self = $self->apply_filters;

    # apply filters to fields labeled as "don't filter automatically" (post)
    $self = $self->apply_filters('post');

=cut

sub apply_filters {

    my ($self, $state) = @_;

    $state ||= 'pre'; # state defaults to (pre) filtering

    # check for and process input filters and default values
    my $run_filter = sub {

        my ($name, $spec) = @_;

        if ($spec->filtering) {

            if ($spec->filtering eq $state) {

                # the filters directive should always be an arrayref
                $spec->filters([$spec->filters]) unless isa_arrayref($spec->filters);

                # apply filters
                $self->apply_filter($_, $name) for @{$spec->filters};

            }

        }

    };

    $self->fields->each($run_filter);

    return $self;

}

sub apply_mixin {

    my ($self, $field, $mixin) = @_;

    return unless $field && $mixin;

    $field = $self->fields->get($field);

    $mixin ||= $field->mixin;

    return unless $mixin && $field;

    # mixin values should be in arrayref form

    my $mixins = isa_arrayref($mixin) ? $mixin : [$mixin];

    foreach my $name (@{$mixins}) {

        my $mixin = $self->mixins->get($name);

        next unless $mixin;

        $self->merge_mixin($field->name, $mixin->name);

    }

    return $self;

}

sub apply_mixin_field {

    my ($self, $field_a, $field_b) = @_;

    return unless $field_a && $field_b;

    $self->check_field($field_a);
    $self->check_field($field_b);

    # some overwriting restricted

    my $fields = $self->fields;

    $field_a = $fields->get($field_a);
    $field_b = $fields->get($field_b);

    return unless $field_a && $field_b;

    my $name  = $field_b->name if $field_b->has('name');
    my $label = $field_b->label if $field_b->has('label');

    # merge

    $self->merge_field($field_a->name, $field_b->name);

    # restore

    $field_b->name($name)   if defined $name;
    $field_b->label($label) if defined $label;

    $self->apply_mixin($name, $field_a->mixin) if $field_a->can('mixin');

    return $self;

}

sub apply_validator {

    my ( $self, $field_name, $field ) = @_;

    # does field have a label, if not use field name (e.g. for errors, etc)

    my $name  = $field->{label} ? $field->{label} : $field_name;
    my $value = $field->{value} ;

    # check if required

    my $req = $field->{required} ? 1 : 0;

    if (defined $field->{'toggle'}) {

        $req = 1 if $field->{'toggle'} eq '+';
        $req = 0 if $field->{'toggle'} eq '-';

    }

    if ( $req && ( !defined $value || $value eq '' ) ) {

        my $error = defined $field->{error} ?
            $field->{error} : "$name is required";

        $field->errors->add($error);

        return $self; # if required and fails, stop processing immediately

    }

    if ( $req || $value ) {

        # find and process all the validators

        foreach my $key (keys %{$field}) {

            my $directive = $self->directives->{$key};

            if ($directive) {

                if ($directive->{validator}) {

                    if ("CODE" eq ref $directive->{validator}) {

                        # execute validator directives
                        $directive->{validator}->(
                            $field->{$key}, $value, $field, $self
                        );

                    }

                }

            }

        }

    }

    return $self;

}

sub check_field {

    my ($self, $name) = @_;

    my $directives = $self->directives;

    my $field = $self->fields->get($name);

    foreach my $key ($field->keys) {

        my $directive = $directives->get($key);

        unless (defined $directive) {
            $self->pitch_error(
                "The $key directive supplied by the ".
                "$name field is not supported"
            );
        }

    }

    return 1;

}

sub check_mixin {

    my ($self, $name) = @_;

    my $directives = $self->directives;

    my $mixin = $self->mixins->get($name);

    foreach my $key ($mixin->keys) {

        my $directive = $directives->get($key);

        unless (defined $directive) {
            $self->pitch_error(
                "The $key directive supplied by the ".
                "$name mixin is not supported"
            );
        }

    }

    return 1;

}

=method class

The class method returns a new initialize validation class related to the
namespace of the calling class, the relative class would've been loaded via the
"load" keyword.

Existing parameters and configuration options are passed to the relative class'
constructor (including the stash). All attributes can be easily overwritten using
the attribute's accessors on the relative class.

Also, you may prevent/override arguments from being copied to the new class
object by supplying the them as arguments to this method.

The class method is also quite handy in that it will detect parameters that are
prefixed with the name of the class being fetched, and adjust the matching rule
(if any) to allow validation to occur.

    package Class;

    use Validation::Class;

    load classes => 1; # load child classes e.g. Class::*

    package main;

    my $input = Class->new(params => $params);

    my $child1  = $input->class('Child');      # loads Class::Child;
    my $child2  = $input->class('StepChild');  # loads Class::StepChild;

    my $child3  = $input->class('child');      # loads Class::Child;
    my $child4  = $input->class('step_child'); # loads Class::StepChild;

    # use any non-alphanumeric character or underscore as the namespace delimiter

    my $child5  = $input->class('step/child'); # loads Class::Step::Child;
    my $child5a = $input->class('step:child'); # loads Class::Step::Child;
    my $child5b = $input->class('step.child'); # loads Class::Step::Child;
    my $child5c = $input->class('step-child'); # loads Class::Step::Child;

    my $child6  = $input->class('CHILD');      # loads Class::CHILD;

    # intelligently detecting and map params to child class

    my $params = {

        'my.name'    => 'Guy Friday',
        'child.name' => 'Guy Friday Jr.'

    };

    $input->class('child'); # child field *name* mapped to param *child.name*

    # without copying params from class

    my $child = $input->class('child', params => {});

    # alternate syntax

    my $child = $input->class(-name => 'child', params => {});

    1;

=cut

sub class {

    my $self = shift;

    my ($name, %args) = @_;

    return unless $name;

    my $class = Class::Forward->new(namespace=>$self->{package})->forward($name);

    return unless $class;

    my @attrs = qw(

        ignore_failure
        ignore_unknown
        report_failure
        report_unknown

    );  # to be copied (stash and params copied later)

    my %defaults = ( map { $_ => $self->$_ } @attrs );

    $defaults{'stash'}  = $self->stashed;     # copy stash
    $defaults{'params'} = $self->get_params;  # copy params

    my %settings = %{ merge \%args, \%defaults };

    use_module $class;

    for (keys %settings) {

        delete $settings{$_} unless $class->can($_);

    }

    return unless $class->can('new');

    my $child = $class->new(%settings);

    {

        my $proto_method =
            $child->can('proto') ? 'proto' :
            $child->can('prototype') ? 'prototype' : undef
        ;

        if ($proto_method) {

            my $proto = $child->$proto_method;

            if (defined $settings{'params'}) {

                foreach my $key ($proto->params->keys) {

                    if ($key =~ /^$name\.(.*)/) {

                        if ($proto->fields->has($1)) {

                            push @{$proto->fields->{$1}->{alias}}, $key;

                        }

                    }

                }

            }

        }

    }

    return $child;

}

=method clear_queue

The clear_queue method resets the queue container, see the queue method for more
information on queuing fields to be validated. The clear_queue method has yet
another useful behavior in that it can assign the values of the queued
parameters to the list it is passed, where the values are assigned in the same
order queued.

    my $self = Class->new(params => $params);

    $self->queue(qw(name +email));

    ...

    $self->queue(qw(+login +password));

    if ($self->validate) {

        $self->clear_queue(my($name, $email));

        print "Name is $name";

    }

=cut

sub clear_queue {

    my $self = shift @_;

    my @names = @{$self->queued};

    $self->queued([]);

    for (my $i = 0; $i < @names; $i++) {

        $names[$i] =~ s/^[\-\+]{1}//;
        $_[$i] = $self->param($names[$i]);

    }

    return @_;

}

=method clone_field

The clone_field method is used to create new fields (rules) from existing fields
on-the-fly. This is useful when you have a variable number of parameters being
validated that can share existing validation rules.

    package Class;

    use Validation::Class;

    field 'phone' => {
        label => 'Your Phone',
        required => 1
    };

    package main;

    my $self = Class->new(params => $params);

    # clone phone rule at run-time to validate dynamically created parameters
    $self->clone_field('phone', 'phone2', { label => 'Phone A', required => 0 });
    $self->clone_field('phone', 'phone3', { label => 'Phone B', required => 0 });
    $self->clone_field('phone', 'phone4', { label => 'Phone C', required => 0 });

    $self->validate(qw/phone phone2 phone3 phone4/);

    1;

=cut

sub clone_field {

    my ($self, $field, $new_field, $directives) = @_;

    $directives ||= {};

    $directives->{name} = $new_field unless $directives->{name};

    # build a new field from an existing one during runtime

    $self->fields->add(
        $new_field => Validation::Class::Field->new($directives)
    );

    $self->apply_mixin_field($new_field, $field);

    return $self;

}

=method error_count

The error_count method returns the total number of errors set at both the class
and field level.

    my $count = $self->error_count;

=cut

sub error_count {

    my ($self) = @_;

    my $i = $self->errors->count;

    $i += $_->errors->count for $self->fields->values;

    return $i;

}

=method error_fields

The error_fields method returns a hashref containing the names of fields which
failed validation and an arrayref of error messages.

    unless ($self->validate) {

        my $failed = $self->error_fields;

    }

    my $suspects = $self->error_fields('field2', 'field3');

=cut

sub error_fields {

    my ($self, @fields) = @_;

    my $failed = {};

    @fields = $self->fields->keys unless @fields;

    foreach my $name (@fields) {

        my $field = $self->fields->{$name};

        if ($field->{errors}->count) {

            $failed->{$name} = $field->{errors}->list;

        }

    }

    return $failed;

}

=method errors_to_string

The errors_to_string method stringifies the all error objects on both the class
and fields using the specified delimiter (defaulting to comma-space (", ")).

    return $self->errors_to_string("\n");
    return $self->errors_to_string(undef, sub{ ucfirst lc shift });

    unless ($self->validate) {

        return $self->errors_to_string;

    }

=cut

sub errors_to_string {

    my $self = shift;

    # combine class anf field errors

    my $errors = Validation::Class::Errors->new([]);

    $errors->add($self->errors->list);

    $errors->add($_->errors->list) for ($self->fields->values);

    return $errors->to_string(@_);

}

=method get_errors

The get_errors method returns a list of combined class-and-field-level errors.

    my @errors = $self->get_errors; # returns list

    my @critical = $self->get_errors(qr/^critical:/i); # filter errors

    my @specific_field_errors = $self->get_errors('field_a', 'field_b');

=cut

sub get_errors {

    my ($self, @criteria) = @_;

    my $errors = Validation::Class::Errors->new([]); # combined errors

    if (!@criteria) {

        $errors->add($self->errors->list);

        $errors->add($_->errors->list) for ($self->fields->values);

    }

    elsif (isa_regexp($criteria[0])) {

        my $query = $criteria[0];

        $errors->add($self->errors->grep($query)->list);
        $errors->add($_->errors->grep($query)->list) for $self->fields->values;

    }

    else {

        $errors->add($_->errors->list)
            for map {$self->fields->get($_)} @criteria;

    }

    return ($errors->list);

}

=method get_fields

The get_fields method returns the list of references to the specified fields.
Returns undef if no arguments are passed. This method is likely to be used more
internally than externally.

    my ($this, $that) = $self->get_fields('this', 'that');

=cut

sub get_fields {

    my ($self, @fields) = @_;

    my $fields = {};

    $self->fields->each(sub{ $fields->{$_[0]} = $_[1] || {} });

    if (@fields) {

        return @fields ? (map { $fields->{$_} || undef } @fields) : ();

    }

    else {

        return $fields;

    }

}

=method get_params

The get_params method returns the values of the parameters specified (as a list,
in the order specified). This method will return a list of key/value pairs if
no parameter names are passed.

    if ($self->validate) {

        my ($name) = $self->get_params('name');

        my ($name, $email, $login, $password) =
            $self->get_params(qw/name email login password/);

        # you should note that if the params don't exist they will return
        # undef meaning you should check that it is defined before doing any
        # comparison checking as doing so would generate an error, e.g.

        if (defined $name) {

            if ($name eq '') {

                print 'name parameter was passed but was empty';

            }

        }

        else {

            print 'name parameter was never submitted';

        }

    }

    # alternatively ...

    my $params = $self->get_params; # return hashref of parameters

    print $params->{name};

=cut

sub get_params {

    my ($self, @params) = @_;

    my $params = $self->params->hash || {};

    if (@params) {

        return @params ? (map { $params->{$_} || undef } @params) : ();

    }

    else {

        return $params;

    }

}

=method get_value

The get_value method returns the absolute value (hardcoded, default or
parameter specified) for a given field. This method executes specific logic
which returns the value a field has based on a set of internal conditions. This
method otherwise returns undefined.

    my $value = $self->get_value('field_name');

=cut

sub get_value {

    my ($self, $name) = @_;

    return 0 unless $self->fields->has($name);

    my $field  = $self->fields->{$name};

    my $value = undef;

    if (exists $self->params->{$name}) {

        $value = $self->params->{$name};

    }

    unless (defined $value) {

        if (exists $field->{default}) {

            $value = "CODE" eq ref $field->{default} ?
                $field->{default}->($self) :
                $field->{default};

        }

    }

    return $value;

}

=method is_valid

The is_valid method returns a boolean value which is true if the last validation
attempt was successful, and false if it was not (which is determined by looking
for errors at the class and field levels).

    return "OK" if $self->is_valid;

=cut

sub is_valid {

    my ($self) = @_;

    my $i = $self->errors->count;

    $i += $_->errors->count for $self->fields->values;

    return $i ? 0 : 1;

}

sub merge_field {

    my ($self, $field_a, $field_b) = @_;

    return unless $field_a && $field_b;

    my $directives = $self->directives;

    $field_a = $self->fields->get($field_a);
    $field_b = $self->fields->get($field_b);

    return unless $field_a && $field_b;

    # keep in mind that in this case we're using field_b as a mixin

    foreach my $pair ($field_b->pairs) {

        my ($key, $value) = @{$pair}{'key', 'value'};

        # skip unless the directive is mixin compatible

        next unless $directives->get($key)->mixin;

        # do not override existing keys but multi values append

        if ($field_a->has($key)) {

            next unless $directives->get($key)->multi;

        }

        if ($directives->get($key)->field) {

            # can the directive have multiple values, merge array

            if ($directives->get($key)->multi) {

                # if field has existing array value, merge unique

                if (isa_arrayref($field_a->{$key})) {

                    my @values = isa_arrayref($value) ? @{$value} : ($value);

                    push @values, @{$field_a->{$key}};

                    @values = uniq @values;

                    $field_a->{$key} = [@values];

                }

                # simple copy

                else {

                    $field_a->{$key} = isa_arrayref($value) ? $value : [$value];

                }

            }

            # simple copy

            else {

                $field_a->{$key} = $value;

            }

        }

    }

    return $self;

}

sub merge_mixin {

    my ($self, $field, $mixin) = @_;

    return unless $field && $mixin;

    my $directives = $self->directives;

    $field = $self->fields->get($field);
    $mixin = $self->mixins->get($mixin);

    foreach my $pair ($mixin->pairs) {

        my ($key, $value) = @{$pair}{'key', 'value'};

        # do not override existing keys but multi values append

        if ($field->has($key)) {

            next unless $directives->get($key)->multi;

        }

        if ($directives->get($key)->field) {

            # can the directive have multiple values, merge array

            if ($directives->get($key)->multi) {

                # if field has existing array value, merge unique

                if (isa_arrayref($field->{$key})) {

                    my @values = isa_arrayref($value) ? @{$value} : ($value);

                    push @values, @{$field->{$key}};

                    @values = uniq @values;

                    $field->{$key} = [@values];

                }

                # merge copy

                else {

                    my @values = isa_arrayref($value) ? @{$value} : ($value);

                    push @values, $field->{$key} if $field->{$key};

                    @values = uniq @values;

                    $field->{$key} = [@values];

                }

            }

            # simple copy

            else {

                $field->{$key} = $value;

            }

        }

    }

    return $field;

}

=method normalize

The normalize method executes a set of routines that reset the parameter
environment filtering any parameters present. This method is executed
automatically at instantiation and again just before each validation event.

    $self->normalize();

=cut

sub normalize {

    my $self = shift;

    # resets

    $self->validated(0);

    $self->reset_fields;

    # validate mixin directives

    foreach my $key ($self->mixins->keys) {

        $self->check_mixin($key);

    }

    # check for and process a mixin directive

    foreach my $key ($self->fields->keys) {

        my $field = $self->fields->get($key);

        next unless $field;

        $self->apply_mixin($key, $field->{mixin})
            if $field->can('mixin') && $field->{mixin};

    }

    # check for and process a mixin_field directive

    foreach my $key ($self->fields->keys) {

        my $field = $self->fields->get($key);

        next unless $field;

        $self->apply_mixin_field($key, $field->{mixin_field})
            if $field->can('mixin_field') && $field->{mixin_field}
        ;

    }

    # execute normalization events

    foreach my $key ($self->fields->keys) {

        $self->trigger_event('on_normalize', $key);

    }

    # alias checking, ... for duplicate aliases, etc

    my $fieldtree = {};
    my $aliastree = {};

    foreach my $pair ($self->fields->pairs) {

        my($name, $field)  = @{$pair}{'key', 'value'};

        $fieldtree->{$name} = $name; # just a counter

        if (defined $field->{alias}) {

            my $aliases = "ARRAY" eq ref $field->{alias}
                ? $field->{alias} : [$field->{alias}];

            foreach my $alias (@{$aliases}) {

                if ($aliastree->{$alias}) {

                    my $error = qq(
                        The field $field contains the alias $alias which is
                        also defined in the field $aliastree->{$alias}
                    );

                    $self->throw_error($error);

                }
                elsif ($fieldtree->{$alias}) {

                    my $error = qq(
                        The field $field contains the alias $alias which is
                        the name of an existing field
                    );

                    $self->throw_error($error);

                }
                else {

                    $aliastree->{$alias} = $field;

                }

            }

        }

    }

    # final checkpoint, validate field directives

    foreach my $key ($self->fields->keys) {

        $self->check_field($key);

    }

    return $self;

}

=method param

The param method gets/sets a single parameter by name. This method returns the
value assigned or undefined if the parameter does not exist.

    my $value = $self->param('name');

    $self->param($name => $value);

=cut

sub param {

    my  ($self, $name, $value) = @_;

    if ($name && !ref($name)) {

        if (defined $value) {

            $self->set_params($name => $value);

            return $value;

        }

        if ($self->params->has($name)) {

            return $self->params->{$name};

        }

    }

    return 0;

}

sub pitch_error {

    my ($self, $error_message) = @_;

    $error_message =~ s/\n/ /g;
    $error_message =~ s/\s+/ /g;

    if ($self->ignore_unknown) {

        if ($self->report_unknown) {

            $self->errors->add($error_message);

        }

    }

    else {

        $self->throw_error($error_message);

    }

    return $self;

}

=method plugin

The plugin method returns the instantiated plugin object attached to the current
class.

    package Class;

    use Validation::Class;

    load plugin => ['TelephoneFormat'];
    load plugin => ['+Class::Plugin::Form::Elements'];

    package main;

    my $input = Class->new(params => $params);

    # get object for Validation::Class::Plugin::TelephoneFormat;

    my $plugin = $input->plugin('telephone_format');

    # use any non-alphanumeric character or underscore as the namespace delimiter
    # get object for Class::Plugin::Form::Elements;
    # note the leading character/delimiter

    # automatically resolves to the first matching namespace for $self
    # or Validation::Class::Plugin

    my $plugin = $input->plugin('plugin:form:elements');

    # prefix with a special character to denote a fully-qualified namespace

    my $plugin = $input->plugin('+class:plugin:form:elements');

    # same as $input->proto->plugins->{'Class::Plugin::Form::Elements'};

    my $plugin = $input->plugin('Class::Plugin::Form::Elements');

=cut

sub plugin {

    my ($self, $class) = @_;

    return 0 unless $class;

    # transform what looks like a shortname

    if ($class !~ /::/) {

        my @parts = split /[^0-9A-Za-z_]/, $class;

        foreach my $part (@parts) {

            $part = ucfirst $part;
            $part =~ s/([a-z])_([a-z])/$1\u$2/g;

        }

        if (!$parts[0]) {

            shift @parts;

            $class = join "::", @parts;

        }

        else {

            my @rootspaces = (

                $self->{package},
                'Validation::Class::Plugin'

            );

            foreach my $rootspace (@rootspaces) {

                $class = join "::", $rootspace, @parts;

                last if eval { $class->can("new") };

            }

        }

    }

    return $self->plugins->{$class};

}

sub proxy_methods {

    return qw{

        class
        clear_queue
        error
        error_count
        error_fields
        errors
        errors_to_string
        get_errors
        get_fields
        get_params
        fields
        filtering
        ignore_failure
        ignore_unknown
        param
        params
        plugin
        queue
        report_failure
        report_unknown
        reset_errors
        reset_fields
        reset_params
        set_errors
        set_fields
        set_params
        stash

    }

}

sub proxy_methods_wrapped {

    return qw{

        validate
        validate_method
        validate_profile

    }

}

=method queue

The queue method is a convenience method used specifically to append the
queued attribute allowing you to *queue* fields to be validated. This method
also allows you to set fields that must always be validated.

    $self->queue(qw/name login/);
    $self->queue(qw/email_confirm/) if $input->param('chg_email');
    $self->queue(qw/password_confirm/) if $input->param('chg_pass');

=cut

sub queue {

    my $self = shift;

    push @{$self->queued}, @_;

    return $self;

}

sub register_attribute {

    my ($self, $attribute, $default) = @_;

    no strict 'refs';
    no warnings 'redefine';

    confess "Error creating accessor '$attribute', name has invalid characters"
        unless $attribute =~ /^[a-zA-Z_]\w*$/;

    confess "Error creating accessor, default must be a coderef or constant"
        if ref $default && ref $default ne 'CODE';

    my $code;

    if (defined $default) {

        $code = sub {

            if (@_ == 1) {
                return $_[0]->{$attribute} if exists $_[0]->{$attribute};
                return $_[0]->{$attribute} = ref $default eq 'CODE' ?
                    $default->($_[0]) : $default;
            }
            $_[0]->{$attribute} = $_[1]; $_[0];

        };

    }

    else {

        $code = sub {

            return $_[0]->{$attribute} if @_ == 1;
            $_[0]->{$attribute} = $_[1]; $_[0];

        };

    }

    $self->set_method($attribute, $code);
    $self->configuration->attributes->add($attribute, $code);

    return $self;

}

sub register_builder {

    my ($self, $code) = @_;

    $self->configuration->builders->add($code);

    return $self;

}

sub register_directive {

    my ($self, $name, $code) = @_;

    my $directive = Validation::Class::Directive->new(
        name      => $name,
        validator => $code
    );

    $self->configuration->directives->add($name, $directive);

    return $self;

}

sub register_field {

    my ($self, $name, $data) = @_;

    my $package = $self->package;

    confess "Error creating field $name, name is using unconventional naming"
        unless $name =~ /^[a-zA-Z_](([\w\.]+)?\w)$/
        xor    $name =~ /^[a-zA-Z_](([\w\.]+)?\w)\:\d+$/;

    confess "Error creating accessor $name on $package: attribute collision"
        if $self->fields->has($name);

    confess "Error creating accessor $name on $package: method collision"
        if $package->can($name);

    $data->{name} = $name;

    $self->configuration->fields->add($name, $data);

    my $subname = $name;

    $subname =~ s/\W/_/g;

    my $routine = sub {

        my ($self, $data) = @_;

        my $proto  = $self->proto;

        if (defined $data) {

            $proto->params->add($name, $data);

        }

        return $proto->params->get($name);

    };

    $self->set_method($subname, $routine);

    return $self;

}

sub register_filter {

    my ($self, $name, $code) = @_;

    $self->configuration->filter->add($name, $code);

    return $self;

}

sub register_method {

    my ($self, $name, $data) = @_;

    my $package = $self->package;

    confess "Error creating method $name on $package: collides with attribute $name"
        if $self->attributes->has($name);

    confess "Error creating method $name on $package: collides with method $name"
        if $package->can($name);

    # create method

    confess "Error creating method $name, requires 'input' and 'using' options"
        unless $data->{input} && $data->{using};

    $self->configuration->methods->add($name, $data);

    no strict 'refs';

    my $method_routine = sub {

        my $self  = shift;
        my @args  = @_;

        my $validator;

        my $input  = $data->{'input'};
        my $using  = $data->{'using'};
        my $output = $data->{'output'};

        if ($input) {

            $validator = "ARRAY" eq ref $input ?

                # validate fields
                sub { $self->validate(@{$input}) } :

                # validate profile
                sub { $self->validate_profile($input, @args) } ;

        }

        if ($using) {

            if ("CODE" eq ref $using) {

                my $error = "Method $name failed to validate";

                # run input validation
                if ("CODE" eq ref $validator) {

                    unless ($validator->(@args)) {

                        unshift @{$self->errors}, $error
                            if $self->report_failure;

                        confess $error. " input, ". $self->errors_to_string
                            if ! $self->ignore_failure;

                        return 0;

                    }

                }

                # execute routine
                my $return = $data->{using}->($self, @args);

                # run output validation
                if ($output) {

                    $validator = "ARRAY" eq ref $output ?

                        # validate fields
                        sub { $self->validate(@{$output}) } :

                        # validate profile
                        sub { $self->validate_profile($output, @args) } ;

                    confess $error. " output, ". $self->errors_to_string
                        unless $validator->(@args);

                }

                return $return;

            }

            else {

                confess "Error executing $name, no associated coderef";

            }

        }

        return 0;

    };

    $self->set_method($name, $method_routine);

    return $self;

}

sub register_mixin {

    my ($self, $name, $data) = @_;

    $data->{name} = $name;

    $self->configuration->mixins->add($name, $data);

    return $self;

}

sub register_profile {

    my ($self, $name, $code) = @_;

    $self->configuration->profiles->add($name, $code);

    return $self;

}

sub register_settings {

    my ($self, $data) = @_;

    my $name = $self->package;

    if ($data->{classes}) {

        my @parents;

        if (! ref $data->{classes} && $data->{classes} == 1) {

            push @parents, $name;

        }

        else {

            push @parents, isa_arrayref($data->{classes}) ?
                @{$data->{classes}} : $data->{classes};

        }

        foreach my $parent (@parents) {

            # load class children and create relationship map (hash)

            foreach my $child (findallmod $parent) {

                my $name  = $child;
                   $name  =~ s/^$parent\:://;

                $self->configuration->relatives->add($name, $child);

            }

        }

    }

    if ($data->{plugins}) {

        my @plugins;

        push @plugins, isa_arrayref($data->{plugins}) ?
            @{$data->{plugins}} : $data->{plugins};

        foreach my $plugin (@plugins) {

            if ($plugin !~ /^\+/) {

                $plugin = "Validation::Class::Plugin::$plugin";

            }

            $plugin =~ s/^\+//;

            eval { use_module $plugin };

        }

        $self->configuration->plugins->add($_, undef) for @plugins;

    }

    # attach roles

    if (grep { $data->{$_} } qw/base bases role roles/) {

        my @roles ;

        my $alias =
            $data->{base}  || $data->{role} ||
            $data->{roles} || $data->{bases}; # backwards compat

        if ($alias) {

            push @roles, isa_arrayref($alias) ?
                @{$alias} : $alias;

        }

        if (@roles) {

            no strict 'refs';

            foreach my $role (@roles) {

                eval { use_module $role };

                my @routines =
                    grep { defined &{"$role\::$_"} }
                    keys %{"$role\::"};

                if (@routines) {

                    # copy methods

                    foreach my $routine (@routines) {

                        eval {

                            $self->set_method($routine, $role->can($routine));

                        }   unless $self->package->can($routine);

                    }

                    my $role_proto = $self->registry->get($role);

                    # merge configurations

                    $self->configuration->profile->merge(
                        $role_proto->configuration->profile->hash
                    );

                }

            }

        }

    }

    return $self;

}

sub registry {

    return $_registry;

}

=method reset

The reset method clears all errors, fields and queued field names, both at the
class and individual field levels.

    $self->reset();

=cut

sub reset {

    my  $self = shift;

        $self->queued([]);

        $self->reset_fields;

        $self->reset_params;

    return $self;

}

=method reset_errors

The reset_errors method clears all errors, both at the class and individual
field levels. This method is called automatically every time the validate()
method is triggered.

    $self->reset_errors();

=cut

sub reset_errors {

    my $self = shift;

    $self->errors->clear;

    foreach my $field ($self->fields->values) {

        $field->errors->clear;

    }

    return $self;

}

=method reset_fields

The reset_fields method clears all errors and field values, both at the class
and individual field levels. This method is executed automatically at
instantiation.

    $self->reset_fields();

=cut

sub reset_fields {

    my $self = shift;

    foreach my $field ( $self->fields->values ) {

        # set default, special directives, etc
        $field->{name}  = $field->name;
        $field->{value} = '';

    }

    $self->reset_errors();

    return $self;

}

=method reset_params

The reset_params method is responsible for completely removing any existing
parameters and adding those specified. This method returns the class object.
This method takes a list of key/value pairs or a single hashref.

    $self = $self->reset_params($new_params); # accepts list also

=cut

sub reset_params {

    my $self = shift;

    my $params = $self->build_args(@_);

    $self->params->clear;

    $self->params->add($params);

    return $self;

}

=method set_errors

The set_errors method pushes its arguments (error messages) onto the class-level
error stack and returns a count of class-level errors.

    my $count = $self->set_errors(..., ...);

=cut

sub set_errors {

    my ($self, @errors) = @_;

    $self->errors->add(@errors) if @errors;

    return $self->errors->count;

}

=method set_fields

The set_fields method is responsible setting/overriding registered fields.
This method returns the class object. This method takes a list of key/value
pairs or a single hashref whose key should be a valid field name and whose
value should be a hashref that is a valid field configuration object.

    $self = $self->set_fields($name => $config); # accepts hashref also

=cut

sub set_fields {

    my $self = shift;

    my $fields = @_ % 2 ? $_[0] : { @_ };

    $self->fields->add($fields);

    return $self;

}

=method set_method

The set_method method conveniently creates a method on the calling class, this
method is primarily intended to be used during instantiation of a plugin during
instantiation of the validation class.

    my $sub = $self->set_method(do_something => sub { ... });

Additionally, method names are flattened, e.g. ThisFunction will be converted to
this_function for convenience and consistency.

=cut

sub set_method {

    my ($self, $name, $code) = @_;

    # proto and prototype methods cannnot be overriden

    confess "Error creating method $name, method already exists"
        if ($name eq 'proto' || $name eq 'prototype')
        && $self->package->can($name)
    ;

    # place routines on the calling class

    no strict   'refs';
    no warnings 'redefine';

    return *{join('::', $self->package, $name)} = $code;

}

=method set_params

The set_params method is responsible for setting/replacing parameters. This
method returns the class object. This method takes a list of key/value pairs or
a single hashref whose keys should match field names and whose value should
be a scalar or arrayref.

    $self->set_params($name => $value); # accepts a hashref also

=cut

sub set_params {

    my $self = shift;

    my $args = @_ % 2 ? $_[0] : { @_ };

    while (my($k,$v) = each(%{$args})) {

        $self->params->add($k => $v); # add new/overwrite existing

    }

    return $self;

}

=method set_value

The set_value method assigns a value to the specified field's parameter
unless the field is readonly.

    $self = $self->set_value($name => $value);

=cut

sub set_value {

    my ($self, $name, $value) = @_;

    if (! $self->fields->has($name)) {

        $self->pitch_error("Field $name does not exist");

    }

    else {

        my $error = qq{
            "Field value for $name must be a scalar value or arrayref"
        };

        $self->throw_error($error)
            if ref($value) && "ARRAY" ne ref $value;

        unless (defined $self->fields->{$name}->{readonly}) {

            $self->params->add($name => $value);

        }

    }

    return $self;

}

sub snapshot {

    my ($self) = @_;

    # clone configuration settings and merge into the prototype
    # ... which makes the prototype kind've a snapshot of the configuration

    if (my $config = $self->configuration->configure_profile) {

        my @clonable_configuration_settings = qw(
            directives
            events
            fields
            filters
            methods
            mixins
            plugins
            profiles
            relatives
        );

        foreach my $name (@clonable_configuration_settings) {

            my $settings = $config->$name->hash;

            $self->$name->clear->merge($settings);

        }

        $self->builders->add($config->builders->list);

    }

    return $self;

}

=method stash

The stash method provides a container for context/instance specific information.
The stash is particularly useful when custom validation routines require insight
into context/instance specific operations.

    package MyApp::Validation;

    use Validation::Class;

    fld 'email' => {

        validation => sub {

            my ($self) = @_;

            my $db = $self->stash('database');

            return $db->find(...) ? 0 : 1 ; # email exists

        }

    };

    package main;

    $self->stash( { database => $dbix_object } );
    $self->stash( database => $dbix_object );

    ...

=cut

sub stash {

    my $self = shift;

    return $self->stashed->get($_[0]) if @_ == 1 && ! ref $_[0];

    $self->stashed->add($_[0]->hash) if @_ == 1 && isa_mapping($_[0]);
    $self->stashed->add($_[0])       if @_ == 1 && isa_hashref($_[0]);
    $self->stashed->add(@_)          if @_ > 1;

    return $self->stashed;

}

sub throw_error {

    my $error_message = pop;

    $error_message =~ s/\n/ /g;
    $error_message =~ s/\s+/ /g;

    confess $error_message ;

}

sub trigger_event {

    my ($self, $event, $field) = @_;

    return unless $event;
    return unless $field;

    my @order;
    my $directives;
    my $process_all = $event eq 'on_normalize' ? 1 : 0;
    my $event_type  = $event eq 'on_normalize' ? 'normalization' : 'validation';

    $event = $self->events->get($event);
    $field = $self->fields->get($field);

    return unless defined $event;
    return unless defined $field;

    # order events via dependency resolution

    $directives = Validation::Class::Directives->new(
        {map{$_=>$self->directives->get($_)}(sort keys %{$event})}
    );
    @order = ($directives->resolve_dependencies($event_type));
    @order = keys(%{$event}) unless @order;

    # execute events

    foreach my $i (@order) {

        # skip if the field doesn't have the subscribing directive
        unless ($process_all) {
            next unless exists $field->{$i};
        }

        my $routine   = $event->{$i};
        my $directive = $directives->get($i);

        # something else might fudge with the params so we wait
        # until now to collect its value
        my $name  = $field->name;
        my $param = $self->params->has($name) ? $self->params->get($name) : undef;

        # execute the directive routine associated with the event
        $routine->($directive, $self, $field, $param);

    }

    return $self;

}

sub unflatten_params {

    my ($self, $hash) = @_;

    $hash ||= $self->params->hash;

    return unflatten($hash) || {};

}

=method validate

The validate method returns true/false depending on whether all specified fields
passed validation checks.

    use MyApp::Validation;

    my $input = MyApp::Validation->new(params => $params);

    # validate specific fields
    unless ($input->validate('field1','field2')){
        return $input->errors_to_string;
    }

    # validate fields based on a regex pattern
    unless ($input->validate(qr/^field(\d+)?/)){
        return $input->errors_to_string;
    }

    # validate existing parameters, if no parameters exist,
    # validate all fields ... which will return true unless field(s) exist
    # with a required directive
    unless ($input->validate()){
        return $input->errors_to_string;
    }

    # validate all fields period, obviously
    unless ($input->validate(keys %{$input->fields})){
        return $input->errors_to_string;
    }

    # validate specific parameters (by name) after mapping them to other fields
    my $parameter_map = {
        user => 'hey_im_not_named_login',
        pass => 'password_is_that_really_you'
    };
    unless ($input->validate($parameter_map)){
        return $input->errors_to_string;
    }

Another cool trick the validate() method can perform is the ability to temporarily
alter whether a field is required or not during run-time. This functionality is
often referred to as the *toggle* function.

This method is important when you define a field (or two or three) as required
or non and want to change that per validation. This is done by calling the
validate() method with a list of fields to be validated and prefixing the
target fields with a plus or minus as follows:

    use MyApp::Validation;

    my $input = MyApp::Validation->new(params => $params);

    # validate specific fields, force name, email and phone to be required
    # regardless of the field definitions directives ... and force the age, sex
    # and birthday to be optional

    my @spec = qw(+name +email +phone -age -sex -birthday);

    unless ($input->validate(@spec)){
        return $input->errors_to_string;
    }

=cut

sub validate {

    my ($self, $context, @fields) = @_;

    confess

        "Context object ($self->{package} class instance) required ".
        "to perform validation" unless $self->{package} eq ref $context

    ;

    # normalize/sanitize

    $self->normalize();

    # create alias map manually if requested
    # ... extremely-deprecated but it remains for back-compat and nostalgia !!!

    my $alias_map;

    if (isa_hashref($fields[0])) {

        $alias_map = $fields[0]; @fields = (); # blank

        while (my($name, $alias) = each(%{$alias_map})) {

            $self->params->add($alias => $self->params->delete($name));

            push @fields, $alias;

        }

    }

    # include queued fields

    if (@{$self->queued}) {

        push @fields, @{$self->queued};

    }

    # include fields from field patterns

    @fields = map { isa_regexp($_) ? (grep { $_ } ($self->fields->sort)) : ($_) }
    @fields;

    # process toggled fields

    foreach my $field (@fields) {

        my ($switch) = $field =~ /^([+-])./;

        if ($switch) {

            # set field toggle directive

            $field =~ s/^[+-]//;

            if (my $field = $self->fields->get($field)) {

                $field->toggle(1) if $switch eq '+';
                $field->toggle(0) if $switch eq '-';

            }

        }

    }

    # determine what to validate and how

    if (@fields && $self->params->count) {
        # validate all parameters against only the fields explicitly
        # requested to be validated
    }

    elsif (!@fields && $self->params->count) {
        # validate all parameters against all defined fields because no fields
        # were explicitly requested to be validated, e.g. not explicitly
        # defining fields to be validated effectively allows the parameters
        # submitted to dictate what gets validated (may not be dangerous)
        @fields = (map { $self->fields->has($_) ? $_ : () } $self->params->keys);
    }

    elsif (@fields && !$self->params->count) {
        # validate fields specified although no parameters were submitted
        # will likely pass validation unless fields exist with a *required*
        # directive or other validation logic expecting a value
    }

    else {
        # validate all defined fields although no parameters were submitted
        # will likely pass validation unless fields exist with a *required*
        # directive or other validation logic expecting a value
        @fields = ($self->fields->keys);
    }

    # establish the bypass validation flag
    $self->stash->{'validation.bypass_event'} = 0;

    # stash the current context object
    $self->stash->{'validation.context'} = $context;

    # report fields requested that do not exist
    $self->pitch_error("Data validation field $_ does not exist")
        for grep {!$self->fields->has($_)} uniq @fields
    ;

    # stash fields targeted for validation
    $self->stash->{'validation.fields'} =
        [grep {$self->fields->has($_)} uniq @fields]
    ;

    # execute on_before_validation events
    $self->trigger_event('on_before_validation', $_)
        for @{$self->stash->{'validation.fields'}}
    ;

    # execute on_validate events
    unless ($self->stash->{'validation.bypass_event'}) {
        $self->trigger_event('on_validate', $_)
            for @{$self->stash->{'validation.fields'}}
        ;
    }

    # execute on_after_validation events
    $self->trigger_event('on_after_validation', $_)
        for @{$self->stash->{'validation.fields'}}
    ;

    # re-establish the bypass validation flag
    $self->stash->{'validation.bypass_event'} = 0;

    # restore params from alias map manually if requested
    # ... extremely-deprecated but it remains for back-compat and nostalgia !!!

    if ( defined $alias_map ) {

        while (my($name, $alias) = each(%{$alias_map})) {

            $self->params->add($name => $self->params->delete($alias));

        }

    }

    return $self->is_valid;

}

=method validate_method

The validate_method method is used to determine whether a self-validating method
will be successful. It does so by validating the methods input specification.
This is useful in circumstances where it is advantageous to know in-advance
whether a self-validating method will pass or fail.

    if ($self->validate_method('password_change')) {

        if ($self->password_change) {

            # ....

        }

    }

=cut

sub validate_method {

    my  ($self, $context, $name, @args) = @_;

    confess
        "Context object ($self->{package} class instance) required ".
        "to perform method validation" unless $self->{package} eq ref $context;

    return 0 unless $name;

    $self->normalize();
    $self->apply_filters('pre');

    my $methspec = $self->methods->{$name};

    my $input = $methspec->{input};

    if ($input) {

        if ("ARRAY" eq ref $input) {

            return $self->validate($context, @{$input});

        }

        else {

            return $self->validate_profile($context, $input, @args);

        }

    }

    return 0;

}

=method validate_profile

The validate_profile method executes a stored validation profile, it requires a
profile name and can be passed additional parameters which get forwarded into the
profile routine in the order received.

    unless ($self->validate_profile('password_change')) {

        print $self->errors_to_string;

    }

    unless ($self->validate_profile('email_change', $dbi_handle)) {

        print $self->errors_to_string;

    }

=cut

sub validate_profile {

    my  ($self, $context, $name, @args) = @_;

    confess
        "Context object ($self->{package} class instance) required ".
        "to perform profile validation" unless $self->{package} eq ref $context
    ;

    return 0 unless $name;

    $self->normalize();
    $self->apply_filters('pre');

    if (isa_coderef($self->profiles->{$name})) {

        return $self->profiles->{$name}->($context, @args);

    }

    return 0;

}

1;
