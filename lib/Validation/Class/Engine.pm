# ABSTRACT: Data Validation Engine for Validation::Class

package Validation::Class::Engine;

use 5.008001;
use strict;
use warnings;

# VERSION

use Carp 'confess';
use Array::Unique;
use Hash::Flatten;
use Hash::Merge 'merge';

=head1 SYNOPSIS

    package MyApp::User;
    
    use Validation::Class;
    
    # a mixin template
    mxn 'basic'  => {
        required   => 1
    };
    
    # a validation rule
    fld 'login'  => {
        label      => 'User Login',
        error      => 'Login invalid.',
        mixin      => 'basic',
        validation => sub {
            my ($self, $this_field, $all_params) = @_;
            return $this_field->{value} eq 'admin' ? 1 : 0;
        }
    };
    
    # a validation rule
    fld 'password'  => {
        label         => 'User Password',
        error         => 'Password invalid.',
        mixin         => 'basic',
        validation    => sub {
            my ($self, $this_field, $all_params) = @_;
            return $this_field->{value} eq 'pass' ? 1 : 0;
        }
    };
    
    # a validation profile
    pro 'registration'  => sub {
        my ($self, @args) = @_;
        return $self->validate(qw(
            +name
            +email
            -login
            +password
        ))
    };
    
    # an auto-validating method
    mth 'register'  => {
        
        input => [qw/+login +password/],
        using => sub {
            
            my ($self, @args) = shift;
            
            # ... do something
            
        }
        
    };
    
    1;

=head1 DESCRIPTION

Validation::Class::Engine provides data validation functionality and acts as a
role applied to Validation::Class.

=head1 DIRECTIVES

    package MyApp::Validation;
    use Validation::Class;
    
    # a validation template
    mixin '...'  => {
        # mixin directives here
        ...
    };
    
    # a validation rule
    field '...'  => {
        # field directives here
        ...
    };
    
    1;
    
When building a validation class, the first encountered and arguably two most
important keyword functions are field() and mixin(), which are used to declare
their respective properties. A mixin() declares a validation template where
its properties are intended to be copied within field() declarations which
declares validation rules, filters and other properties.

Both the field() and mixin() declarations/functions require two parameters, the
first being a name, used to identify the declaration and to be matched against
incoming input parameters and the second being a hashref of key/value pairs.
The key(s) within a declaration are commonly referred to as directives.

The following is a list of default directives which can be used in field/mixin
declarations:

=cut

=head2 alias

The alias directive is useful when many different parameters with different
names can be validated using a single rule. E.g. The paging parameters in a
webapp may take on different names but require the same validation.

    # the alias directive
    field 'pager'  => {
        alias => ['page_user_list', 'page_other_list']
        ...
    };

=cut

=head2 default

The default directive is used as a default value for a field to be used
when a matching parameter is not present.

    # the default directive
    field 'quantity'  => {
        default => 1,
        ...
    };

=cut

=head2 error/errors

The error/errors directive is used to replace the system generated error
messages when a particular field doesn't validate. If a field fails multiple
directives, multiple errors will be generated for the same field. This may not
be desirable, the error directive overrides this behavior and only the specified
error is registered and displayed.

    # the error(s) directive
    field 'foobar'  => {
        errors => 'Foobar failed processing, Wtf?',
        ...
    };

=cut

=head2 filtering

The filtering directive is used to control when field filters are applied. The
default recognized values are pre/post. A value of 'pre' instructs the validation
class to apply the field's filters at instantiation and before validation whereas
a value of 'post' instructs the validation class to apply the field's filters
after validation. Alternatively, a value of undef or '' will bypass filtering
altogether.

    # the filtering directive
    field 'foobar'  => {
        filtering => 'post',
        ...
    };

=cut

=head2 label

The label directive is used as a user-friendly reference when the field name
is a serialized hash key or just plain ugly.

    # the label directive
    field 'hashref.foo.bar'  => {
        label => 'Foo Bar',
        ...
    };

=cut

=head2 mixin

The mixin directive is used to create a template of directives to be applied to
other fields.

    mixin 'ID' => {
        required => 1,
        min_length => 1,
        max_length => 11
    };

    # the mixin directive
    field 'user.id'  => {
        mixin => 'ID',
        ...
    };

=cut

=head2 mixin_field

The mixin directive is used to copy all directives from an existing field
except for the name, label, and validation directives.

    # the mixin_field directive
    field 'foobar'  => {
        label => 'Foo Bar',
        required => 1
    };
    
    field 'barbaz'  => {
        mixin_field => 'foobar',
        label => 'Bar Baz',
        ...
    };

=cut

=head2 name

The name directive is used *internally* and cannot be changed.

    # the name directive
    field 'thename'  => {
        ...
    };

=cut

=head2 required

The required directive is an important directive but can be misunderstood.
The required directive is used to ensure the submitted parameter exists and
has a value. If the parameter is never submitted, the directive is effectively
skipped. This directive can be thought of as the "must-have-a-value-if-exists"
directive.

    # the required directive
    field 'foobar'  => {
        required => 1,
        ...
    };
    
    # fail
    my $rules = MyApp::Validation->new(params => {  });
    $rules->validate('foobar');
    
    # fail
    my $rules = MyApp::Validation->new(params => { foobar => '' });
    $rules->validate('foobar');
    
    # pass
    my $rules = MyApp::Validation->new(params => {  foobar => 'Nice' });
    $rules->validate('foobar');
    
See the toggle functionality within the validate() method. This method allows
you to temporarily alter whether a field is required or not.

=cut

=head2 validation

The validation directive is a coderef used add additional custom validation to
the field. The coderef must return true (to pass) or false (to fail). Custom
error messages can be set from within the coderef so make sure they are set
based on appropriate logic as the registration of error message are not
contingent on the success or failure of the routine. 

    # the validation directive
    field 'login'  => {
        validation => sub {
            my ($self, $this_field, $all_params) = @_;
            return 0 unless $this_field->{value};
            return $this_field->{value} eq 'admin' ? 1 : 0;
        },
        ...
    };

=cut

=head2 value

The value directive is used internally to store the field's matching parameter's
value. This value can be set in the definition but SHOULD NOT be used as a
default value unless you're sure no parameter will overwrite it during run-time.
If you need to set a default value, see the default directive.

    # the value directive
    field 'quantity'  => {
        value => 1,
        ...
    };

=cut

=head2 filters

The filters directive is used to correct, alter and/or format the
values of the matching input parameter. Note: Filtering is applied before
validation. The filter directive can have multiple filters (even a coderef)
in the form of an arrayref of values.

    # the filter(s) directive
    field 'text'  => {
        filters => [qw/trim strip/ => sub {
            $_[0] =~ s/\D//g;
        }],
        ...
    };
    
The following is a list of default filters that may be used with the filter
directive:

=cut

=head3 alpha

The alpha filter removes all non-Alphabetic characters from the field's value.

    field 'foobar'  => {
        filter => 'alpha',
    };
    
=cut

=head3 alphanumeric

The alpha filter removes all non-Alphabetic and non-Numeric characters from the
field's value.

    field 'foobar'  => {
        filter => 'alphanumeric',
    };
    
=cut

=head3 capitalize

The capitalize filter attempts to capitalize the first word in each sentence,
where sentences are separated by a period and space, within the field's value.

    field 'foobar'  => {
        filter => 'capitalize',
    };
    
=cut

=head3 decimal

The decimal filter removes all non-decimal-based characters from the field's
value. Allows only: decimal, comma, and numbers.

    field 'foobar'  => {
        filter => 'decimal',
    };
    
=cut

=head3 numeric

The numeric filter removes all non-numeric characters from the field's
value.

    field 'foobar'  => {
        filter => 'numeric',
    };
    
=cut

=head3 strip

As with the trim filter the strip filter removes leading and trailing
whitespaces from the field's value and additionally removes multiple whitespaces
from between the values characters.

    field 'foobar'  => {
        filter => 'strip',
    };
    
=cut

=head3 titlecase

The titlecase filter converts the field's value to titlecase by capitalizing the
first letter of each word.

    field 'foobar'  => {
        filter => 'titlecase',
    };
    
=cut

=head3 trim

The trim filter removes leading and trailing whitespace from the field's value.

    field 'foobar'  => {
        filter => 'trim',
    };
    
=cut

=head3 uppercase

The uppercase filter converts the field's value to uppercase.

    field 'foobar'  => {
        filter => 'uppercase',
    };
    
=cut

=head2 validators

    package MyApp::Validation;
    
    use Validation::Class;
    
    # a validation rule with validator directives
    field 'telephone_number'  => {
        length => 14,
        pattern => '(###) ###-####',
        ...
    };
    
    1;
    
Validator directives are special directives with associated validation code that
is used to validate common use cases such as "checking the length of a parameter",
etc.

The following is a list of the default validators which can be used in field/mixin
declarations:

=cut

=head2 between

    # the between directive
    field 'foobar'  => {
        between => '1-5',
        ...
    };

=cut

=head2 depends_on

    # the depends_on directive
    field 'change_password'  => {
        depends_on => ['password', 'password_confirm'],
        ...
    };

=cut

=head2 length

    # the length directive
    field 'foobar'  => {
        length => 20,
        ...
    };

=cut

=head2 matches

    # the matches directive
    field 'this_field'  => {
        matches => 'another_field',
        ...
    };

=cut

=head2 max_alpha

    # the max_alpha directive
    field 'password'  => {
        max_alpha => 30,
        ...
    };

=cut

=head2 max_digits

    # the max_digits directive
    field 'password'  => {
        max_digits => 5,
        ...
    };

=cut

=head2 max_length

    # the max_length directive
    field 'foobar'  => {
        max_length => '...',
        ...
    };

=cut

=head2 max_sum

    # the max_sum directive
    field 'vacation_days'  => {
        max_sum => 5,
        ...
    };

=cut

=head2 max_symbols

    # the max_symbols directive
    field 'password'  => {
        max_symbols => 1,
        ...
    };

=cut

=head2 min_alpha

    # the min_alpha directive
    field 'password'  => {
        min_alpha => 2,
        ...
    };

=cut

=head2 min_digits

    # the min_digits directive
    field 'password'  => {
        min_digits => 1,
        ...
    };

=cut

=head2 min_length

    # the min_length directive
    field 'foobar'  => {
        min_length => '...',
        ...
    };

=cut

=head2 min_sum

    # the min_sum directive
    field 'vacation_days'  => {
        min_sum => 0,
        ...
    };

=cut

=head2 min_symbols

    # the min_symbols directive
    field 'password'  => {
        min_symbols => 0,
        ...
    };

=cut

=head2 options

    # the options directive
    field 'status'  => {
        options => 'Active, Inactive',
        ...
    };

=cut

=head2 pattern

    # the pattern directive
    field 'telephone'  => {
        # simple pattern
        pattern => '### ###-####',
        ...
    };
    
    field 'country_code'  => {
        # simple pattern
        pattern => 'XX',
        filter  => 'uppercase'
        ...
    };
    
    field 'complex'  => {
        # regex pattern
        pattern => qr/[0-9]+\,\s\.\.\./,
        ...
    };

=cut

# hackaroni toni, stolen from youknowwho ...
sub has {

    my ($attrs, $default) = @_;

    return unless $attrs;

    confess "Error creating accessor, default must be a coderef or constant"
      if ref $default && ref $default ne 'CODE';

    $attrs = [$attrs] unless ref $attrs eq 'ARRAY';

    for my $attr (@$attrs) {

        confess "Error creating accessor \"$attr\", name has invalid characters"
            unless $attr =~ /^[a-zA-Z_]\w*$/;

        my $stmnt;

        $stmnt = <<"STMNT";
        sub {
            
            if (\@_ == 1) { 
STMNT

        $stmnt .= <<"STMNT" unless (defined $default);
                return \$_[0]->{'$attr'};
STMNT
        
        $stmnt .= <<"STMNT" if ref $default eq 'CODE';
                return \$_[0]->{'$attr'} if exists \$_[0]->{'$attr'};
                return \$_[0]->{'$attr'} = \$default->(\$_[0]);
STMNT

        $stmnt .= <<"STMNT" if ref $default ne 'CODE';
                return \$_[0]->{'$attr'} if exists \$_[0]->{'$attr'};
                return \$_[0]->{'$attr'} = \$default;
STMNT
        
        $stmnt .= <<"STMNT";
            }
            
            \$_[0]->{'$attr'} = \$_[1];
            \$_[0];
        }
STMNT
        
        no strict 'refs';
        no warnings 'redefine';
        
        *{__PACKAGE__."::$attr"} = eval $stmnt;

        confess(__PACKAGE__ . " attribute compiler error: \n$stmnt\n$@\n") if $@;

    }
    
}

=attribute directives

The directives attribute returns a hashref of all defined directives.

    my $directives = $self->directives();
    ...

=cut

has 'directives' => sub { shift->{config}->{DIRECTIVES} || {} };

=attribute errors

The errors attribute returns an arrayref of all errors set.

    my $errors = $self->errors();
    ...

=cut

has 'errors' => sub {[  ]};

=attribute fields

The fields attribute returns a hashref of defined fields, filtered and merged
with their parameter counterparts.

    my $fields = $self->fields();
    ...

=cut

has 'fields' => sub { shift->{config}->{FIELDS} || {} };

=attribute filtering

The filtering attribute (by default set to 'pre') controls when incoming data
is filtered. Setting this attribute to 'post' will defer filtering until after
validation occurs which allows any errors messages to report errors based on the
unaltered data. Alternatively, setting the filtering attribute to '' or undef
will bypass all filtering unless explicitly defined at the field-level.

    my $filtering = $self->filtering('post');
    
    $self->validate();
    ...

=cut

has 'filtering' => 'pre';

=attribute filters

The filters attribute returns a hashref of pre-defined filter definitions.

    my $filters = $self->filters();
    ...

=cut

has 'filters' => sub { shift->{config}->{FILTERS} || {} };

=attribute hash_inflator

The hash_inflator attribute determines how the hash serializer (inflation/deflation)
behaves. The value must be a hashref of L<Hash::Flatten/OPTIONS> options. Purely
for the sake of consistency, you can use lowercase keys (with underscores) which
will be converted to camel-cased keys before passed to the serializer.

    my $options = $self->hash_inflator({
        hash_delimiter => '/',
        array_delimiter => '//'
    });
    ...

=cut

has 'hash_inflator' => sub {
    
    my $options = @_ > 1 ? pop @_ : {
        hash_delimiter  => '.',
        array_delimiter => ':',
        escape_sequence => '',
    };
    
    foreach my $option (keys %{$options}) {
        
        if ($option =~ /\_/) {
        
            my $cc_option = $option;
            
            $cc_option =~ s/([a-zA-Z])\_([a-zA-Z])/$1\u$2/gi;
            
            $options->{ucfirst $cc_option} = $options->{$option};
            
            delete $options->{$option};
        
        }
        
    }

    return $options;
    
};

=attribute ignore_failure

The ignore_failure boolean determines whether your application will live or die
upon failing to validate a self-validating method defined using the method
keyword. This is on (1) by default, method validation failures will set errors
and can be determined by checking the error stack using one of the error message
methods. If turned off, the application will die and confess on failure.

    my $ignoring = $self->ignore_failure(1);
    ...

=cut

has 'ignore_failure' => '1';

=attribute ignore_unknown

The ignore_unknown boolean determines whether your application will live or die
upon encountering unregistered field directives during validation. This is off
(0) by default, attempts to validate unknown fields WILL cause the program to die.

    my $ignoring = $self->ignore_unknown(1);
    ...

=cut

has 'ignore_unknown' => '0';

=attribute methods

The methods attribute returns a hashref of self-validating method definitions.

    my $methods = $self->methods(); # definitions are hashrefs
    ...

=cut

has 'methods' => sub { shift->{config}->{METHODS} || {} };

=attribute mixins

The mixins attribute returns a hashref of defined validation templates.

    my $mixins = $self->mixins();
    ...

=cut

has 'mixins' => sub { shift->{config}->{MIXINS} || {} };

=attribute params

The params attribute gets/sets the parameters to be validated. The assigned value
MUST be a hashref but can be flat or complex.

    my $params = $self->params();
    ...

=cut

has 'params' => sub {{  }};

=attribute plugins

The plugins attribute returns a hashref of loaded plugins.

    my $plugins = $self->plugins();
    ...

=cut

has plugins => sub { shift->{config}->{PLUGINS} || {} };

=attribute profiles

The profiles attribute returns a hashref of validation profiles.

    my $profiles = $self->profiles();
    ...

=cut

has 'profiles' => sub { shift->{config}->{PROFILES} || {} };

=attribute queued

The queued attribute returns an arrayref of field names for (auto) validation.
It represents a list of field names stored to be used in validation later. If
the queued attribute contains a list, you can omit arguments to the validate
method. 

    my $queued = $self->queued([qw/.../]);
    ...

=cut

has 'queued' => sub { [] };

=attribute relatives

The relatives attribute returns a hashref of short-name/class-name pairs of
loaded child classes.

    my $relatives = $self->relatives();
    ...

=cut

# class relatives (child-classes) store
has 'relatives' => sub {{  }};

=attribute report_failure

The report_failure boolean determines whether your application will report
self-validating method failures as class-level errors. This is off (0) by default,
if turned on, an error messages will be generated and set at the class-level
specifying the method which failed in addition to the existing messages.

    my $reporting = $self->report_failure(0);
    ...

=cut

# switch: report method requirement failures
has 'report_failure' => '0';

=attribute report_unknown

The report_unknown boolean determines whether your application will report
unregistered fields as class-level errors upon encountering unregistered field
directives during validation. This is off (0) by default, attempts to validate
unknown fields will NOT be registered as class-level variables.

    my $reporting = $self->report_unknown(1);
    ...

=cut

# switch: report unknown input parameters
has 'report_unknown' => '0';

# stash object storage
has 'stashed' => sub {{  }};

# hash of directives by type
has 'types' => sub {
    
    my $self  = shift;
    my $types = { mixin => {}, field => {} };
    my $dirts = $self->directives;
    
    # build types hash from directives by their usability
    while (my($name, $directive) = each(%{$dirts})) {
        
        $types->{mixin}->{$name} = $directive if $dirts->{$name}->{mixin};
        $types->{field}->{$name} = $directive if $dirts->{$name}->{field};
        
    }
    
    return $types;
    
};

=method apply_filters

The apply_filters method (usually called automatically based on the filtering
attribute) can be used to run the currently defined parameters through the
filters defined in the fields.

    my $input = Class->new(filtering => '', params => $params);
    
    if ($input->validate) {
        $input->apply_filters; # basically post filtering
    }

=cut

sub apply_filters {
    
    my ($self, $state) = @_;
    
    $state ||= 'pre'; # state defaults to (pre) filtering
    
    # check for and process input filters and default values
    while (my($name, $field) = each(%{$self->fields})) {
        
        if ($field->{filtering} eq $state) {
            
            # the filters directive should always be an arrayref
            $field->{filters} = [$field->{filters}] unless
                "ARRAY" eq ref $field->{filters};
                
            # apply filters
            $self->use_filter($_, $name) for @{$field->{filters}};
            
            # set default value - absolute last resort
            if (defined $self->params->{$field}) {
                if (!$self->params->{$field}) {
                    if ($field->{default}) {
                        $self->params->{$field} = $field->{default};
                    }
                }
            }
        }
    }
    
    return $self;

}

=method class

The class method returns a new initialize validation class related to the
namespace of the calling class, the relative class would've been loaded via the
"load" keyword.

Existing parameters and configuration options are passed to the relative class'
constructor (including the stash). All attributes can be easily overwritten using
the attribute's accessors on the relative class.

Also, you may prevent/override arguments from being copy to the new class object
by supplying the them as arguments to this method.

The class method is also quite handy in that it will detect parameters that are
prefixed with the name of the class being fetched, and adjust the matching rule
(if any) to allow validation to occur.

    package Class;
    
    use Validation::Class;
    
    load {
        classes => 1 # load child classes e.g. Class::*
    };
    
    package main;
    
    my $input = Class->new(params => $params);
    
    my $kid1 = $input->class('Child');      # loads Class::Child;
    my $kid2 = $input->class('StepChild');  # loads Class::StepChild;
    
    my $kid3 = $input->class('child');      # loads Class::Child;
    my $kid4 = $input->class('step_child'); # loads Class::StepChild;
    my $kid5 = $input->class('step-child'); # loads Class::Step::Child;
    
    # intelligently detecting and map params to child class
    
    my $params = {
        'my.name'    => 'Guy Friday',
        'child.name' => 'Guy Friday Jr.'
    };
    
    $input->class('child'); # child field *name* mapped to param *child.name*
    
    # without copying params from class
    
    my $kid5 = $input->class('child', params => {}); # .. etc
    
    1;

=cut

sub class {
    
    my ( $self, $class, %args ) = @_;
    
    #confess 'Relative class does not exist, please ensure you are calling the class '.
    #    'method from the parent class, i.e. the class where you called the '.
    #    'load_classes method' unless defined $self->relatives->{$class};
    
    return unless defined $self->relatives->{$class};
    
    my %defaults = (    
        'params'         => $self->params,
        'stashed'        => $self->stashed,
        'ignore_unknown' => $self->ignore_unknown,
        'report_unknown' => $self->report_unknown,
        'hash_inflator'  => $self->hash_inflator
    );
    
    my $child = $self->relatives->{$class}->new(merge(\%args, \%defaults));
    my $delimiter = $self->hash_inflator->{'HashDelimiter'};
    
    $delimiter =~ s/([\.\+\-\:\,\\\/])/\\$1/g;
    
    foreach my $name (keys %{$child->params}) {
        
        if ($name =~ /^$class$delimiter(.*)/) {
            
            if (defined $child->fields->{$1}) {
                
                push @{$child->fields->{$1}->{alias}}, $name;
                
            }
            
        }
        
    }
    
    return $child;

}

sub check_field {
    
    my ( $self, $field, $spec ) = @_;

    my $directives = $self->types->{field};

    foreach ( keys %{$spec} ) {
        
        # if the field has a directive not listed in the directives table
        # error !!!
        if ( ! defined $directives->{$_} ) {
            my $death_cert = "The $_ directive supplied by the $field ".
                             "field is not supported";

            $self->xxx_suicide_by_unknown_field($death_cert);
        }
        
    }

    return 1;

}

sub check_mixin {
    
    my ( $self, $mixin, $spec ) = @_;

    my $directives = $self->types->{mixin};

    foreach ( keys %{$spec} ) {
        if ( ! defined $directives->{$_} ) {
            my $death_cert =
              "The $_ directive supplied by the $mixin mixin is not supported";
            $self->xxx_suicide_by_unknown_field($death_cert);
        }
        if ( ! $directives->{$_} ) {
            my $death_cert =
              "The $_ directive supplied by the $mixin mixin is empty";
            $self->xxx_suicide_by_unknown_field($death_cert);
        }
    }

    return 1;

}

=method clear_queue

The clear_queue method resets the queue container, see the queue method for more
information on queuing fields to be validated. The clear_queue method has yet
another useful behavior in that it can assign the values of the queued
parameters to the list it is passed, where the values are assigned in the same
order queued.

    my $input = Class->new(params => $params);
    
    $input->queue(qw(name +email +login +password));
    
    unless ($input->validate) {
        return $input->errors_to_string;
    }
    
    $input->clear_queue(my($name, $email));
    
    1;

=cut

sub clear_queue {
    
    my $self = shift;
    
    my @names = @{$self->queued};
    
    $self->queued([]);
    
    for (my $i = 0; $i < @names; $i++) {
        $names[$i] =~ s/^[\-\+]{1}//;
        $_[$i] = $self->params->{$names[$i]};
    }
    
    return @_;

}

=method clone

The clone method is used to create new fields (rules) from existing fields
on-the-fly. This is useful when you have a variable number of parameters being
validated that can share existing validation rules. E.g., a web-form on a user's
profile page may have dynamically created input boxes for the person's phone
numbers allowing the user to add additional parameters to the web-form as
needed, in that case as opposed to having multiple validation rules hardcoded
for each parameter, you could hardcode one single rule and clone the rule at
run-time.

    package Class;
    use Validation::Class;
    
    field phone => { required => 1 };
    
    package main;
    
    my $input = Class->new(params => $params);
    
    # clone phone rule at run-time to validate dynamically created parameters
    $input->clone('phone', 'phone2', { label => 'Other Phone', required => 0 });
    $input->clone('phone', 'phone3', { label => 'Third Phone', required => 0 });
    $input->clone('phone', 'phone4', { label => 'Forth Phone', required => 0 });
    
    $input->validate(qw/phone phone2 phone3 phone4/);
    
    1;

=cut

sub clone {
    
    my ($self, $field_name, $new_field_name, $directives) = @_;
    
    # build a new field from an existing one during runtime
    $self->fields->{$new_field_name} = $directives || {};
    $self->use_mixin_field( $field_name, $new_field_name );
    
    return $self;
    
}

=method error

The error method is used to set and/or retrieve errors encountered during
validation. The error method with no parameters returns the error message object
which is an arrayref of error messages stored at class-level. 

    # set errors at the class-level
    return $self->error('this isnt cool', 'unknown somethingorother');
    
    # set an error at the field-level, using the field ref (not field name)
    $self->error($field_object, "i am your error message");

    # return all errors encountered/set as an arrayref
    my $all_errors = $self->error();
    
    # return all error for a specific field, ... see the get_errors() method
    my @errors = $self->get_errors('field_name');

=cut

sub error {
    
    my ( $self, @args ) = @_;

    # set an error message on a particular field
    if ( @args == 2 ) {

        # set error message
        my ( $field, $error ) = @args;
        
        # field must be a reference (hashref) to a field object
        if ( ref($field) eq "HASH" && ( !ref($error) && $error ) ) {

            # temporary, may break stuff
            $error = $field->{error} if defined $field->{error};

            # add error to field-level errors
            push @{$field->{errors}}, $error unless
                grep { $_ eq $error } @{$field->{errors}};
            
            # add error to class-level errors    
            push @{$self->errors}, $error unless
                grep { $_ eq $error } @{$self->errors};
        }
        else {
            
            confess "Can't set error without proper field and error "
              . "message data, field must be a hashref with name "
              . "and value keys";
            
        }
    
    }
    
    # retrieve an error message on a particular field
    if ( @args == 1 ) {

        #if ($self->fields->{$args[0]}) {
        
            # return param-specific errors
            #return $self->fields->{$args[0]}->{errors};
        
        #}
        #else {
            
            # add error to class-level errors    
            return push @{$self->errors}, $args[0] unless
                grep { $_ eq $args[0] } @{$self->errors};
            
        #}
        
    }
    
    # return all class-level error messages
    return $self->errors;
    
}

=method error_count

The error_count method returns the total number of error encountered from the 
last validation call.

    return $self->error_count();
    
    unless ($self->validate) {
        print "Found ". $self->error_count ." Errors";
    }

=cut

sub error_count {
    
    return scalar(@{shift->errors});
    
}

=method error_fields

The error_fields method returns a hashref of fields whose value is an arrayref
of error messages.

    unless ($self->validate) {
        my $bad_fields = $self->error_fields();
    }
    
    my $bad_fields = $self->error_fields('login', 'password');

=cut

sub error_fields {
    
    my ($self, @fields) = @_;
    
    my $error_fields = {};
    
    @fields = keys %{$self->fields} unless @fields;
    
    foreach my $name (@fields) {
        
        my $field = $self->fields->{$name};
        
        if (@{$field->{errors}}) {
            
            $error_fields->{$name} = $field->{errors};
        
        }
        
    }
    
    return $error_fields;

}

=method errors_to_string

The errors_to_string method stringifies the error arrayref object using the
specified delimiter or ', ' by default. 

    return $self->errors_to_string("<br/>\n");
    return $self->errors_to_string("<br/>\n", sub{ uc shift });
    
    unless ($self->validate) {
        return $self->errors_to_string;
    }

=cut

sub errors_to_string {
    
    my ($self, $delimiter, $transformer) = @_;
    
    $delimiter ||= ', '; # default delimiter is a comma
    
    return join $delimiter, @{$self->errors} unless "CODE" eq ref $transformer;
    
    return join $delimiter, map { $transformer->($_) } @{$self->errors};

}

=method get_errors

The get_errors method returns the list of class-level error set on the current
class or a list of errors from the specified fields.

    my @errors = $self->get_errors();
    my @lp_errors = $self->get_errors('login', 'password');

=cut

sub get_errors {

    my ($self, @fields) = @_;
    
    # get class-level errors as a list
    return @fields ?
        (map { @{$self->fields->{$_}->{errors}} } @fields) :
        (@{$self->{errors}});

}

=method get_params

The get_params method returns the values (in list form) of the parameters
specified.

    if ($self->validate) {
        my $name_a = $self->get_params('name');
        my ($name_b, $email, $login, $password) =
            $self->get_params(qw/name email login password/);
        
        # you should note that if the params dont exist they will return undef
        # ... meaning you should check that it exists before checking its value
        # e.g.
        
        if (defined $name) {
            if ($name eq '') {
                print 'name parameter was passed but was empty';
            }
        }
        else {
            print 'name parameter was never submitted';
        }
    }

=cut

sub get_params {

    my ($self, @params) = @_;
    
    # get param values as a list
    return @params ?
        (map { $self->params->{$_} } @params) :
        (values %{ $self->params });
    
}

=method get_params_hash

If your fields and parameters are designed with complex hash structures, the
get_params_hash method returns the deserialized hashref of specified parameters
based on the the default or custom configuration of the hash serializer
L<Hash::Flatten>.

    my $params = {
        'user.login' => 'member',
        'user.password' => 'abc123456'
    };
    
    if ($self->validate(keys %$params)) {
        my $params = $self->get_params_hash;
        print $params->{user}->{login};
    }

=cut

sub get_params_hash {
    
    my ($self, $params) = @_;
    
    $params ||= $self->params;
    
    my $serializer = Hash::Flatten->new($self->hash_inflator);
    
    $params = $serializer->unflatten($params);
    
    return $params;
    
}

=method normalize

The normalize method executes a set of routines that reset the parameter
environment filtering any parameters present. This method is executed
automatically at instantiation and validation. 

    $self->normalize();

=cut

sub normalize {
    
    my $self = shift;
    
    # automatically serialize params if nested hash is detected
    if (grep { ref($_) } values %{$self->params}) {
        $self->set_params_hash($self->params);
    }
    
    # reset fields
    $self->reset_fields;

    # validate mixin directives
    while (my($name, $mixin) = each(%{ $self->mixins })) {
        $self->check_mixin($name, $mixin);
    }

    # validate field directives and create default directives if needed
    while (my($name, $field) = each(%{$self->fields})) {
        
        $self->check_field($name, $field);
        
        # by default fields should have a filters directive
        if (!defined $field->{filters}) {
            $field->{filters} = [];
        }
        
        # by default fields should have a filtering directive
        if (!defined $field->{filtering}) {
            $field->{filtering} = $self->filtering if $self->filtering;
        }
        
        # static labels and error messages may contain multiline
        # strings for the sake of aesthetics, correct this
        foreach my $string ('error', 'label') {
            if (defined $field->{$string}) {
                $field->{$string} =~ s/^[\n\s\t\r]+//g;
                $field->{$string} =~ s/[\n\s\t\r]+$//g;
                $field->{$string} =~ s/[\n\s\t\r]+/ /g;
            }
        }
        
    }

    # check for and process a mixin directive
    while (my($name, $field) = each(%{$self->fields})) {
        $self->use_mixin($name, $field->{mixin}) if $field->{mixin};
    }

    # check for and process a mixin_field directive
    while (my($name, $field) = each(%{$self->fields})) {
    
        if ($field->{mixin_field}) {
            $self->use_mixin_field($field->{mixin_field}, $name)
                if $self->fields->{$field->{mixin_field}};
        }

    }

    # alias checking, ... for duplicate aliases, etc
    my $fieldtree = {};
    my $aliastree = {};
    
    while (my($name, $field) = each(%{$self->fields})) {
        
        $fieldtree->{$name} = $name; # just a counter
        
        if (defined $field->{alias}) {
            
            my $aliases = "ARRAY" eq ref $field->{alias}
                ? $field->{alias} : [$field->{alias}];
            
            foreach my $alias (@{$aliases}) {
                
                if ($aliastree->{$alias}) {
                    confess "The field $field contains the alias $alias which is "
                      . "also defined in the field $aliastree->{$alias}";
                }
                elsif ($fieldtree->{$alias}) {
                    confess "The field $field contains the alias $alias which is "
                      . "the name of an existing field";
                }
                else {
                    $aliastree->{$alias} = $field;
                }
                
            }
            
        }
        
    }
    
    # restore order to the land
    $self->reset_fields;
    
    return $self;

}

=method param

The param method gets/sets a single parameter by name.

    my $pass = $self->param('password');
    
    $self->param('password', '******');

=cut

sub param {
    
    my  ($self, $name, $value) = @_;
    
    return 0 unless $name;
    
    $self->params->{$name} = $value if defined $value;
    
    return $self->params->{$name};

}

=method queue

The queue method is a convenience method used specifically to append the
stashed attribute allowing you to *queue* field to be validated. This method
also allows you to set fields that must always be validated. 

    # conditional validation flow WITHOUT the queue method
    # imagine a user profile update action
    
    my $input = MyApp::Validation->new(params => $params);
    my @fields = qw/name login/;
    
    push @fields, 'email_confirm' if $input->param('chg_email');
    push @fields, 'password_confirm' if $input->param('chg_pass');
    
    ... if $input->validate(@fields);
    
    # conditional validation WITH the queue method
    
    my $input = MyApp::Validation->new(params => $params);
    
    $input->queue(qw/name login/);
    $input->queue(qw/email_confirm/) if $input->param('chg_email');
    $input->queue(qw/password_confirm/) if $input->param('chg_pass');
    
    ... if $input->validate();
    
    # set fields that must ALWAYS be validated
    # imagine a simple REST server
    
    my $input = MyApp::Validation->new(params => $params);
    
    $input->queue(qw/login password/);
    
    if ($request eq '/resource/:id') {
        
        if ($input->validate('id')) {
            
            # validated login, password and id
            ...
        }
    }

=cut

sub queue {
    
    my $self = shift;
    
    push @{$self->queued}, @_;
    
    return $self;

}

=method reset

The reset method clears all errors, fields and stashed field names, both at the
class and individual field levels.

    $self->reset();

=cut

sub reset {

    my  $self = shift;
    
        $self->queued([]);
        
        $self->reset_fields;
        
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
       
       $self->errors([]);
    
    foreach my $field (values %{$self->fields}) {
        $field->{errors} = [];
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
    
    foreach my $field ( keys %{ $self->fields } ) {
        
        # set default, special directives, etc
        $self->fields->{$field}->{name} = $field;
        $self->fields->{$field}->{'&toggle'} = undef;
        delete $self->fields->{$field}->{value};
        
    }
    
    $self->reset_errors();
    
    return $self;

}

=method set_errors

The set_errors method pushes its arguments (error messages) onto the class-level
error stack of the current class.

    my $count = $self->set_errors('Oops', 'OMG', 'WTF');

=cut

sub set_errors {

    my ($self, @errors) = @_;
    
    # set class-level errors from list
    return push @{$self->{errors}}, @errors if @errors;

}

=method set_method

The set_method method conveniently creates a method on the calling class, this
method is primarily intended to be used during instantiation of a plugin during
instantiation of the validation class.

Additionally, method names are flattened, e.g. ThisPackage will be converted to
this_package for convenience and consistency.

    my $sub = $self->set_method(__PACKAGE__ => sub { ... });

=cut

sub set_method {
    
    my ($self, $name, $code) = @_;
    
    my $class = ref $self || $self;
    
    my $shortname  = $name;
       $shortname  =~ s/::/\_/g;
       $shortname  =~ s/[^a-zA-Z0-9\_]/\_/g;
       $shortname  =~ s/([a-z])([A-Z])/$1\_$2/g;
       $shortname  = lc $shortname;
       
    confess "Error creating method $shortname, method already exists"
        if $class->can($shortname);
    
    # place code on the calling class
    
    no strict 'refs';
    
    *{"${class}::$shortname"} = $code;
    
}

=method set_params_hash

Depending on how parameters are being input into your application, if your
input parameters are already complex hash structures, The set_params_hash method
will set and return the serialized version of your hashref based on the the
default or custom configuration of the hash serializer L<Hash::Flatten>.

    my $params = {
        user => {
            login => 'member',
            password => 'abc123456'
        }
    };
    
    my $serialized_params = $self->set_params_hash($params);

=cut

sub set_params_hash {

    my ($self, $params) = @_;
    
    $params = $self->get_params_hash($params);
    
    my $serializer = Hash::Flatten->new($self->hash_inflator);
    
    return $self->params($serializer->flatten($params));

}

=method stash

The stash method provides a container for context/instance specific information.
The stash is particularly useful when custom validation routines require insight
into context/instance specific operations.

    package MyApp::Validation;
    
    use Validation::Class;
    
    fld 'email' => {
        validation => sub {
            my $db = shift->stash->{database};
            my $this = shift;
            
            return $db->find('email' => $this->{value}) ? 0 : 1 ; # email exists
        }
    };
    
    package main;
    
    $self->stash( { database => $dbix_object } );
    $self->stash( ftp => $net_ftp, database => $dbix_object );
    
    ...

=cut

sub stash {

    my ($self, @requests) = @_;
    
    if (@requests) {
        
        if (@requests == 1) {
            
            my $request = $requests[0];
            
            if ("HASH" eq ref $request) {
                
                @requests = %{$request};
                
            }
            else {
                
                return $self->stashed->{$request};
                
            }
            
        }
        
        if (@requests > 1) {
            
            my %data = @requests;
            
            while (my($key, $value) = each %data) {
                
                $self->stashed->{$key} = $value;
                
            }
            
        }
        
    }
    
    return $self->stashed;

}

sub template {
    
    {
        
        DIRECTIVES => {
            
            '&toggle' => {
                
                mixin => 0,
                field => 1,
                multi => 0
                
            },
            
            alias => {
                
                mixin => 0,
                field => 1,
                multi => 1
                
            },
            
            between => {
                
                mixin     => 1,
                field     => 1,
                multi     => 0,
                
                validator => sub {
                    
                    my ($directive, $value, $field, $class) = @_;
                    my ($min, $max) = "ARRAY" eq ref $directive ?
                        @{$directive} :
                        split /(?:\s{1,})?[,\-]{1,}(?:\s{1,})?/, $directive;
                    
                    $min = scalar($min);
                    $max = scalar($max);
                    $value = length($value);
                    
                    if ($value) {
                    
                        unless ($value >= $min && $value <= $max) {
                    
                            my $handle = $field->{label} || $field->{name};
                            my $error  =
                                "$handle must contain between ".
                                "$directive characters";
                            
                            $class->error($field, $error);
                            
                            return 0;
                    
                        }
                    
                    }
                    
                    return 1;
                
                }
                
            },
            
            default => {
                
                mixin => 1,
                field => 1,
                multi => 1
                
            },
            
            depends_on => {
            
                mixin     => 1,
                field     => 1,
                multi     => 1,
            
                validator => sub {
            
                    my ($directive, $value, $field, $class) = @_;
                    
                    if ($value) {
                        
                        my $dependents = "ARRAY" eq ref $directive ?
                        $directive : [$directive];
                        
                        if (@{$dependents}) {
                            
                            my @blanks = ();
            
                            foreach my $dep (@{$dependents}) {
            
                                push @blanks,
                                    $class->fields->{$dep}->{label} ||
                                    $class->fields->{$dep}->{name} 
                                    if ! $class->params->{$dep};
            
                            }
                                
                            if (@blanks) {
            
                                my $handle = $field->{label} || $field->{name};
            
                                $class->error(
                                    $field, "$handle requires " .
                                    join(", ", @blanks) . " to have " .
                                    (@blanks > 1 ? "values" : "a value")
                                );
            
                                return 0;
            
                            }
            
                        }
                        
                    }
                    
                    return 1;
            
                }
            
            },
            
            error => {
            
                mixin => 0,
                field => 1,
                multi => 0
            
            },
            
            errors => {
            
                mixin => 0,
                field => 1,
                multi => 0
            
            },
            
            filters => {
            
                mixin => 1,
                field => 1,
                multi => 1
            
            },
            
            filtering => {
            
                mixin => 1,
                field => 1,
                multi => 1
            
            },
            
            label => {
            
                mixin => 0,
                field => 1,
                multi => 0
           
            },
           
            length => {
           
                mixin     => 1,
                field     => 1,
                multi     => 0,
           
                validator => sub {
           
                    my ($directive, $value, $field, $class) = @_;
                    
                    $value = length($value);
                    
                    if ($value) {
           
                        unless ($value == $directive) {
           
                            my $handle = $field->{label} || $field->{name};
                            my $characters = $directive > 1 ?
                            "characters" : "character";
                            
                            $class->error(
                                $field, "$handle must contain exactly "
                                ."$directive $characters"
                            );
           
                            return 0;
           
                        }
           
                    }
           
                    return 1;
           
                }
           
            },
           
            matches => {
           
                mixin     => 1,
                field     => 1,
                multi     => 0,
           
                validator => sub {
           
                    my ( $directive, $value, $field, $class ) = @_;
           
                    if ($value) {
                        # build the regex
                        my $this = $value;
                        my $that = $class->params->{$directive} || '';
                        unless ( $this eq $that ) {
                            my $handle  = $field->{label} || $field->{name};
                            my $handle2 = $class->fields->{$directive}->{label}
                                || $class->fields->{$directive}->{name};
                            my $error = "$handle does not match $handle2";
                            $class->error( $field, $error );
           
                            return 0;
           
                        }
           
                    }
           
                    return 1;
           
                }
           
            },
           
            max_alpha => {
                
                mixin     => 1,
                field     => 1,
                multi     => 0,
                
                validator => sub {
                
                    my ( $directive, $value, $field, $class ) = @_;
                
                    if ($value) {
                
                        my @i = ($value =~ /[a-zA-Z]/g);
                
                        unless ( @i <= $directive ) {
                
                            my $handle = $field->{label} || $field->{name};
                            my $characters = int( $directive ) > 1 ?
                                "characters" : "character";
                            my $error = "$handle must contain at-least "
                            ."$directive alphabetic $characters";
                            
                            $class->error( $field, $error );
                
                            return 0;
                
                        }
                
                    }
                
                    return 1;
                
                }
            
            },
            
            max_digits => {
            
                mixin     => 1,
                field     => 1,
                multi     => 0,
            
                validator => sub {
            
                    my ( $directive, $value, $field, $class ) = @_;
            
                    if ($value) {
            
                        my @i = ($value =~ /[0-9]/g);
            
                        unless ( @i <= $directive ) {
            
                            my $handle = $field->{label} || $field->{name};
                            my $characters = int( $directive ) > 1 ?
                                "digits" : "digit";
                            my $error = "$handle must contain at-least "
                            ."$directive $characters";
                            
                            $class->error( $field, $error );
                            return 0;
            
                        }
            
                    }
            
                    return 1;
            
                }
            
            },
            
            max_length => {
            
                mixin     => 1,
                field     => 1,
                multi     => 0,
            
                validator => sub {
            
                    my ( $directive, $value, $field, $class ) = @_;
            
                    if ($value) {
            
                        unless ( length($value) <= $directive ) {
            
                            my $handle = $field->{label} || $field->{name};
                            my $characters = int( $directive ) > 1 ?
                                "characters" : "character";
                            my $error = "$handle can't contain more than "
                            ."$directive $characters";
                            
                            $class->error( $field, $error );
            
                            return 0;
            
                        }
            
                    }
            
                    return 1;
            
                }
            
            },
            
            max_sum => {
            
                mixin     => 1,
                field     => 1,
                multi     => 0,
            
                validator => sub {
            
                    my ( $directive, $value, $field, $class ) = @_;
            
                    if ($value) {
            
                        unless ( $value <= $directive ) {
            
                            my $handle = $field->{label} || $field->{name};
                            my $error = "$handle can't be greater than "
                            ."$directive";
                            
                            $class->error( $field, $error );
                            return 0;
            
                        }
            
                    }
            
                    return 1;
            
                }
            
            },
            
            max_symbols => {
            
                mixin     => 1,
                field     => 1,
                multi     => 0,
            
                validator => sub {
            
                    my ( $directive, $value, $field, $class ) = @_;
            
                    if ($value) {
            
                        my @i = ($value =~ /[^0-9a-zA-Z]/g);
            
                        unless ( @i <= $directive ) {
            
                            my $handle = $field->{label} || $field->{name};
                            my $characters = int( $directive ) > 1 ?
                                "symbols" : "symbol";
                            my $error = "$handle can't contain more than "
                            ."$directive $characters";
                            
                            $class->error( $field, $error );
            
                            return 0;
            
                        }
            
                    }
            
                    return 1;
            
                }
            
            },
            
            min_alpha => {
            
                mixin     => 1,
                field     => 1,
                multi     => 0,
            
                validator => sub {
            
                    my ( $directive, $value, $field, $class ) = @_;
            
                    if ($value) {
            
                        my @i = ($value =~ /[a-zA-Z]/g);
            
                        unless ( @i >= $directive ) {
            
                            my $handle = $field->{label} || $field->{name};
                            my $characters = int( $directive ) > 1 ?
                                "characters" : "character";
                            my $error = "$handle must contain at-least "
                            ."$directive alphabetic $characters";
                            
                            $class->error( $field, $error );
            
                            return 0;
            
                        }
            
                    }
            
                    return 1;
            
                }
            
            },
            
            min_digits => {
            
                mixin     => 1,
                field     => 1,
                multi     => 0,
            
                validator => sub {
            
                    my ( $directive, $value, $field, $class ) = @_;
            
                    if ($value) {
            
                        my @i = ($value =~ /[0-9]/g);
            
                        unless ( @i >= $directive ) {
            
                            my $handle = $field->{label} || $field->{name};
                            my $characters = int( $directive ) > 1 ?
                                "digits" : "digit";
                            my $error = "$handle must contain at-least "
                            ."$directive $characters";
                            
                            $class->error( $field, $error );
            
                            return 0;
            
                        }
            
                    }
            
                    return 1;
            
                }
            
            },
            
            min_length => {
            
                mixin     => 1,
                field     => 1,
                multi     => 0,
            
                validator => sub {
            
                    my ( $directive, $value, $field, $class ) = @_;
            
                    if ($value) {
            
                        unless ( length($value) >= $directive ) {
            
                            my $handle = $field->{label} || $field->{name};
                            my $characters = int( $directive ) > 1 ?
                                "characters" : "character";
                            my $error = "$handle must contain at-least "
                            ."$directive $characters";
                            
                            $class->error( $field, $error );
            
                            return 0;
            
                        }
            
                    }
            
                    return 1;
            
                }
            
            },
            
            min_sum => {
            
                mixin     => 1,
                field     => 1,
                multi     => 0,
            
                validator => sub {
            
                    my ( $directive, $value, $field, $class ) = @_;
            
                    if ($value) {
            
                        unless ( $value >= $directive ) {
            
                            my $handle = $field->{label} || $field->{name};
                            my $error = "$handle can't be less than "
                            ."$directive";
                            
                            $class->error( $field, $error );
            
                            return 0;
            
                        }
            
                    }
            
                    return 1;
            
                }
            
            },
            
            min_symbols => {
            
                mixin     => 1,
                field     => 1,
                multi     => 0,
            
                validator => sub {
            
                    my ( $directive, $value, $field, $class ) = @_;
            
                    if ($value) {
            
                        my @i = ($value =~ /[^0-9a-zA-Z]/g);
            
                        unless ( @i >= $directive ) {
            
                            my $handle = $field->{label} || $field->{name};
                            my $characters = int( $directive ) > 1 ?
                                "symbols" : "symbol";
                            my $error = "$handle must contain at-least "
                            ."$directive $characters";
                            
                            $class->error( $field, $error );
            
                            return 0;
            
                        }
            
                    }
            
                    return 1;
            
                }
            
            },
            
            mixin => {
            
                mixin => 0,
                field => 1,
                multi => 1
            
            },
            
            mixin_field => {
            
                mixin => 0,
                field => 1,
                multi => 0
            
            },
            
            name => {
            
                mixin => 0,
                field => 1,
                multi => 0
            
            },
            
            options => {
            
                mixin     => 1,
                field     => 1,
                multi     => 0,
            
                validator => sub {
            
                    my ( $directive, $value, $field, $class ) = @_;
            
                    if ($value) {
            
                        # build the regex
                        my (@options) =
                            split /(?:\s{1,})?[,]{1,}(?:\s{1,})?/, $directive;
            
                        unless ( grep { $value =~ /^$_$/ } @options ) {
            
                            my $handle  = $field->{label} || $field->{name};
                            my $error = "$handle must be " . join " or ", @options;
                            $class->error( $field, $error );
            
                            return 0;
            
                        }
            
                    }
            
                    return 1;
            
                }
            
            },
            
            pattern => {
            
                mixin     => 1,
                field     => 1,
                multi     => 0,
            
                validator => sub {
            
                    my ( $directive, $value, $field, $class ) = @_;
            
                    if ($value) {
            
                        # build the regex
                        my $regex = $directive;
            
                        unless ("Regexp" eq ref $regex) {
            
                            $regex =~ s/([^#X ])/\\$1/g;
                            $regex =~ s/#/\\d/g;
                            $regex =~ s/X/[a-zA-Z]/g;
                            $regex = qr/$regex/;
            
                        }
            
                        unless ( $value =~ $regex ) {
            
                            my $handle = $field->{label} || $field->{name};
                            my $error = "$handle does not match the "
                            ."pattern $directive";
                            
                            $class->error( $field, $error );
            
                            return 0;
            
                        }
            
                    }
            
                    return 1;
            
                }
            
            },
            
            required => {
            
                mixin => 1,
                field => 1,
                multi => 0
            
            },
            
            validation => {
            
                mixin => 0,
                field => 1,
                multi => 0
            
            },
            
            value => {
            
                mixin => 1,
                field => 1,
                multi => 1
            
            }
        
        },
        
        FIELDS     => {},
        
        FILTERS    => {
        
            alpha => sub {
        
                $_[0] =~ s/[^A-Za-z]//g;
                $_[0];
        
            },
        
            alphanumeric => sub {
        
                $_[0] =~ s/[^A-Za-z0-9]//g;
                $_[0];
        
            },
        
            capitalize => sub {
        
                $_[0] = ucfirst $_[0];
                $_[0] =~ s/\.\s+([a-z])/\. \U$1/g;
                $_[0];
        
            },
        
            decimal => sub {
        
                $_[0] =~ s/[^0-9\.\,]//g;
                $_[0];
        
            },
        
            lowercase => sub {
        
                lc $_[0];
        
            },
        
            numeric => sub {
        
                $_[0] =~ s/\D//g;
                $_[0];
        
            },
        
            strip => sub {
        
                $_[0] =~ s/\s+/ /g;
                $_[0] =~ s/^\s+//;
                $_[0] =~ s/\s+$//;
                $_[0];
        
            },
        
            titlecase => sub {
        
                join( " ", map ( ucfirst, split( /\s/, lc $_[0] ) ) );
        
            },
        
            trim => sub {
        
                $_[0] =~ s/^\s+//g;
                $_[0] =~ s/\s+$//g;
                $_[0];
        
            },
        
            uppercase => sub {
        
                uc $_[0];
        
            }
        
        },
        
        MIXINS     => {},
        
        PLUGINS    => {},
        
        PROFILES   => {},
    
    }
    
}

sub use_filter {

    my ($self, $filter, $field) = @_;

    if (defined $self->params->{$field}) {
        
        if ($self->filters->{$filter} || "CODE" eq ref $filter) {
        
            if ($self->params->{$field}) {
                my $code = "CODE" eq ref $filter ?
                    $filter : $self->filters->{$filter};
                
                $self->fields->{$field}->{value} = $self->params->{$field} =
                    $code->( $self->params->{$field} );
            }
        
        }
        
    }
    
    return $self;

}

sub use_mixin {

    my ($self, $field, $mixin) = @_;

    # mixin values should be in arrayref form
    my $mixins = ref($mixin) eq "ARRAY" ? $mixin : [$mixin];

    foreach my $mixin (@{$mixins}) {
        
        if (defined $self->{mixins}->{$mixin}) {
            
            $self->fields->{$field} = $self->xxx_merge_field_with_mixin(
                $self->fields->{$field},
                $self->{mixins}->{$mixin}
            );
            
        }
        
    }

    return $self;

}

sub use_mixin_field {

    my ($self, $field, $target) = @_;
    
    $self->check_field( $field, $self->fields->{$field} );

    # name and label overwrite restricted
    my $name = $self->fields->{$target}->{name}
      if defined $self->fields->{$target}->{name};
    
    my $label = $self->fields->{$target}->{label}
      if defined $self->fields->{$target}->{label};

    $self->fields->{$target} = $self->xxx_merge_field_with_field(
        $self->fields->{$target},
        $self->fields->{$field}
    );

    $self->fields->{$target}->{name}  = $name  if defined $name;
    $self->fields->{$target}->{label} = $label if defined $label;

    foreach my $key ( keys %{$self->fields->{$field}}) {
        $self->use_mixin( $target, $key ) if $key eq 'mixin';
    }

    return $self;

}

sub use_validator {

    my ( $self, $field_name, $field ) = @_;

    # does field have a label, if not use field name (e.g. for errors, etc)
    my $name  = $field->{label} ? $field->{label} : $field_name;
    my $value = $field->{value} ;

    # check if required
    my $req = $field->{required} ? 1 : 0;
    
    if (defined $field->{'&toggle'}) {
        $req = 1 if $field->{'&toggle'} eq '+';
        $req = 0 if $field->{'&toggle'} eq '-';
    }
    
    if ( $req && ( !defined $value || $value eq '' ) ) {
        my $error = defined $field->{error} ?
            $field->{error} : "$name is required";
        
        $self->error( $field, $error );
        
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

    my ( $self, @fields ) = @_;
    
    # first things first, reset the errors and values, etc,
    # returning the validation class to its pristine state
    $self->normalize();
    $self->apply_filters('pre') if $self->filtering;
    $self->reset_fields();
    $self->reset_errors();
    
    # include fields queued by the queue method
    if (@{$self->queued}) {
        push @fields, @{$self->queued};
    }
    
    # process field patterns
    my @new_fields = ();
    
    foreach my $field (@fields) {
        
        if ("Regexp" eq ref $field) {
            push @new_fields, grep { $_ =~ $field }
                sort keys %{$self->fields};
        }
        else {
            push @new_fields, $field;
        }
        
    }
    
    @fields = @new_fields;
    
    # process toggled fields
    foreach my $field (@fields) {
        
        my ($switch) = $field =~ /^([\-\+]{1})./; 
        
        if ($switch) {
            
            # set fields toggle directive
            $field =~ s/^[\-\+]{1}//;
            $self->fields->{$field}->{'&toggle'} = $switch;
        }
        
    }
    
    # save unaltered state-of-parameters
    my %original_parameters = %{$self->params};

    # create alias map manually if requested
    # sorta DEPRECIATED
    if ( "HASH" eq ref $fields[0] ) {
        
        my $alias_map = $fields[0]; @fields = (); # blank
        
        while (my($name, $alias) = each(%{$alias_map})) {
            
            $self->params->{$alias} = delete $self->params->{$name};
            push @fields, $alias;
            
        }
        
    }
    
    # create a map from aliases if applicable
    while (my($name, $field) = each(%{$self->fields})) {
        
        if (defined $field->{alias}) {
            
            my $aliases = "ARRAY" eq ref $field->{alias} ?
                $field->{alias} : [$field->{alias}];
            
            foreach my $alias (@{$aliases}) {
                
                if (defined $self->params->{$alias}) {
                    
                    $self->params->{$name} = delete $self->params->{$alias};
                    push @fields, $name;
                    
                }
                
            }
            
        }
        
    }

    if ( values %{$self->params} ) {
        
        # check for parameters the are arrayrefs and handle them appropriately
        my $params = $self->params;
        
        my ($ad, $hd) = @{$self->hash_inflator}{'ArrayDelimiter', 'HashDelimiter'};
        # ^^ pun here
        
        my %seen = ();
        
        while (my($key, $value) = each(%{$params})) {
            
            next unless my ($name) = $key =~ /(.*)$ad\d+$/;
            
            next unless not $seen{$name};
            
            my $field = $self->fields->{$name};
            
            next unless $field;
            
            $seen{$name}++;
        
            my $varcount = scalar grep { /$name$ad\d+$/ } keys %{ $params };
            
            for (my $i = 0; $i < $varcount; $i++) {
                
                next if defined $self->fields->{"$name:$i"};
                
                my $label = ($field->{label} || $field->{name});
                
                $self->clone($name, "$name:$i", {
                    label => $label . " #" . ($i+1)
                }); 
                
                push @fields, "$name:$i" # black hackery
                    if @fields && grep { $_ eq $name } @fields;
                
            }
            
            # like it never existed ...
            @fields = grep { $_ ne $name } @fields if @fields; # ... 
            
        }
        
        # validate all parameters against all defined fields because no fields
        # were explicitly requested to be validated
        if ( !@fields ) {

            # process all params
            while (my($name, $param) = each(%{$self->params})) {
                
                if ( !defined $self->fields->{$name} ) {
                    $self->xxx_suicide_by_unknown_field(
                        "Data validation field $name does not exist"
                    );
                    next;
                }
                
                my $field = $self->fields->{$name};
                
                $field->{name}  = $name;
                $field->{value} = exists $self->params->{$name} ?
                    $param : $field->{default} || '';
                
                # create arguments to be passed to the validation directive
                my @args = ($self, $field, $self->params);

                # execute validator directives
                $self->use_validator($name, $field);

                # execute custom/validation directive
                if (defined $field->{validation} && $field->{value}) {
                    
                    my $errcnt = $self->error_count;
                    
                    unless ($field->{validation}->(@args)) {
                        
                        # assuming the validation routine didnt issue an error
                        if ($errcnt == $self->error_count) {
                            
                            if (defined $field->{error}) {
                                $self->error($field, $field->{error});
                            }
                            else {
                                
                                my $error_msg =
                                    (($field->{label} || $field->{name})
                                    . " did not pass validation");
                                
                                $self->error($field, $error_msg);
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        # validate all parameters against only the fields explicitly
        # requested to be validated
        else {
            
            foreach my $field_name (@fields) {
                
                if (!defined $self->fields->{$field_name}) {
                    
                    $self->xxx_suicide_by_unknown_field(
                        "Data validation field $field_name does not exist"
                    );
                    next;
                    
                }
                
                my $field = $self->fields->{$field_name};
                
                $field->{name}  = $field_name;
                $field->{value} = exists $self->params->{$field_name} ?
                    $self->params->{$field_name} : $field->{default} || '';
                    
                my @args = ($self, $field, $self->params);

                # execute simple validation
                $self->use_validator($field_name, $field);

                # custom validation
                if (defined $field->{validation} && $field->{value}) {
                    
                    my $errcnt = $self->error_count;
                    
                    unless ($field->{validation}->(@args)) {
                        
                        # assuming the validation routine didnt issue an error
                        if ($errcnt == $self->error_count) {
                            
                            if ( defined $field->{error} ) {
                                $self->error($field, $field->{error});
                            }
                            else {
                                
                                my $error_msg =
                                    (($field->{label} || $field->{name}) .
                                    " did not pass validation");
                                    
                                $self->error($field, $error_msg);
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    else {
        
        # validate fields although no parameters were submitted
        # will likely pass validation unless fields exist with
        # a `required` directive or other validation logic
        # expecting a value
        if (@fields) {
            
            foreach my $field_name (@fields) {
                
                if ( !defined $self->fields->{$field_name} ) {
                    
                    $self->xxx_suicide_by_unknown_field(
                        "Data validation field $field_name does not exist"
                    );
                    next;
                    
                }
                
                my $field = $self->fields->{$field_name};
                
                $field->{name}  = $field_name;
                $field->{value} = exists $self->params->{$field_name} ?
                    $self->params->{$field_name} : $field->{default} || '';
                
                my @args = ($self, $field, $self->params);

                # execute simple validation
                $self->use_validator($field_name, $field);

                # custom validation
                if (defined $field->{validation} && $field->{value}) {
                    
                    my $errcnt = $self->error_count;
                    
                    unless ($field->{validation}->(@args)) {
                        
                        # assuming the validation routine didnt issue an error
                        if ($errcnt == $self->error_count) {
                            
                            if (defined $field->{error}) {
                                $self->error($field, $field->{error});
                            }
                            else {
                                
                                my $error_msg =
                                    (($field->{label} || $field->{name}) .
                                     " did not pass validation");
                                
                                $self->error($field, $error_msg);
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }

        # if no parameters (or) fields are found ... you're screwed :)
        # instead of dying, warn and continue, depending on configuration
        else {
            
            my $error = "No parameters were submitted and no fields are "
                      . "registered. Fields and parameters are required "
                      . "for proper validation.";
            
            if ($self->ignore_unknown) {
                if ($self->report_unknown) {
                    $self->set_errors($error)
                        unless grep { $_ eq $error } @{ $self->errors };
                }
            }
            else {
                confess $error ;
            }
            
        }
        
    }
    
    my $valid = @{ $self->errors } ? 0 : 1;
    
    # restore sanity
    $self->params({%original_parameters});
    
    # run post-validation filtering
    $self->apply_filters('post') if $self->filtering && $valid;

    return $valid;    # returns true if no errors

}

=method validate_profile

The validate_profile method executes a stored validation profile, it requires a
profile name and can be passed additional parameters which get forwarded into the
profile routine in the order received.

    unless ($self->validate_profile('password_change')) {
        die $self->errors_to_string;
    }
    
    unless ($self->validate_profile('email_change', $dbi_handle)) {
        die $self->errors_to_string;
    }

=cut

sub validate_profile {

    my  ($self, $name, @args) = @_;
    
    return 0 unless $name;
    
    # first things first, reset the errors and values, etc,
    # returning the validation class to its pristine state
    $self->normalize();
    $self->apply_filters('pre') if $self->filtering;
    $self->reset_fields();
    $self->reset_errors();
    
    if ("CODE" eq ref $self->profiles->{$name}) {
        
        return $self->profiles->{$name}->($self, @args)
        
    }
    
    return 0;

}

sub xxx_suicide_by_unknown_field {

    my ($self, $error) = @_;
    
    if ($self->ignore_unknown) {
        
        if ($self->report_unknown) {
            $self->set_errors($error)
                unless grep { $_ eq $error } @{ $self->errors };
        }
        
    }
    else {
        confess $error ;
    }
    
}

sub xxx_merge_field_with_mixin {

    my ($self, $field, $mixin) = @_;
    
    while (my($key,$value) = each(%{$mixin})) {
        
        # do not override existing keys but multi values append
        if (grep { $key eq $_ } keys %{$field}) {
            next unless $self->types->{field}->{$key}->{multi};
        }
        
        if (defined $self->types->{field}->{$key}) {
            
            # can the directive have multiple values, merge array
            if ($self->types->{field}->{$key}->{multi}) {
                
                # if field has existing array value, merge unique
                if ("ARRAY" eq ref $field->{$key}) {
                    
                    tie my @values, 'Array::Unique';
                    
                    push @{$field->{$key}},
                    "ARRAY" eq ref $value ? @{$value} : $value;
                    
                    $field->{$key} = [@{$field->{$key}}];
                    
                }
                
                # merge copy
                else {
                    
                    tie my @values, 'Array::Unique';
                    
                    @values = "ARRAY" eq ref $value ?
                    @{$value} : ($value);
                    
                    push @values, $field->{$key} if $field->{$key};
                    
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

sub xxx_merge_field_with_field {

    my ($self, $field, $mixin_field) = @_;
    
    while (my($key,$value) = each(%{$mixin_field})) {
        
        # skip unless the directive is mixin compatible
        next unless $self->types->{mixin}->{$key}->{mixin};
        
        # do not override existing keys but multi values append
        if (grep { $key eq $_ } keys %{$field}) {
            next unless $self->types->{field}->{$key}->{multi};
        }
        
        if (defined $self->types->{field}->{$key}) {
            
            # can the directive have multiple values, merge array
            if ($self->types->{field}->{$key}->{multi}) {
                
                # if field has existing array value, merge unique
                if ("ARRAY" eq ref $field->{key}) {
                    
                    tie my @values, 'Array::Unique';
                    
                    push @{$field->{$key}},
                    "ARRAY" eq ref $value ? @{$value} : $value;
                    
                    $field->{$key} = [@{$field->{$key}}];
                }
                
                # simple copy
                else {
                    
                    $field->{$key} =
                    "ARRAY" eq ref $value ? [@{$value}] : $value;
                    
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

1;