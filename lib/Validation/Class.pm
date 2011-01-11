package Validation::Class;
# ABSTRACT: Centralized Input Validation For Any Application

use strict;
use warnings;
use 5.008001;
use Array::Unique;
use Hash::Merge qw/merge/;
use Data::Dumper::Concise;

BEGIN {
    use Exporter();
    use vars qw( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );
    @ISA    = qw( Exporter );
    @EXPORT = qw(
        new
        field
        mixin
        validation_schema
    );
    @EXPORT_OK = qw(
        new
        setup
        field
        mixin
        error
        errors
        check_field
        check_mixin
        validate
        use_mixin
        use_mixin_field
        basic_validate
        basic_filter
        Oogly
    );
    %EXPORT_TAGS = ( all => [ @EXPORT_OK ] );
}

=head1 SYNOPSIS

Validation::Class is a different approach to data validation, it attempts to simplify and
centralize data validation rules to ensure DRY (don't repeat yourself) code. The primary
intent of this module is to provide a simplistic validation work-flow and promote code
(validation) reuse. The following is an example of that...

    use MyApp::Validation;
    
    my $input = MyApp::Validation->new($params);
    unless ($input->validate('login', 'password')){
        return $input->errors;
    }

=head1 BASIC USAGE

    package MyApp::Validation
    use Validation::Class;

    # define a mixin, a sortof template that can be included with other rules
    # by using the mixin directive
    
    mixin 'default' => {
        required    => 1,
        min_length  => 4,
        max_length  => 255
    };
    
    # define a data validation rule for parameter `login` using the default
    # mixin where the `login` must be between 4-255 characters long and have
    # at least one letter and number
    
    field 'login' => {
        label => 'user login',
        mixin => 'default',
        validation => sub {
            my ($self, $this, $params) = @_;
            my ($name, $value) = ($this->{label}, $params->{login});
            $self->error($this, "$name must contain at least one letter and number")
                unless ($value =~ /[a-zA-Z]/ || $value =~ /[0-9]/);
        }
    };
    
    # define a data validation rule for parameter `password` using the
    # previously defined field `login` as the mixin (template)
    
    field 'password' => {
        mixin_field => 'login',
        label => 'user password'
    };

=head1 CLASSLESS USAGE
    
And now for my second and final act, using Validation::Class outside of a package.

    #!/usr/bin/perl
    use Validation::Class;
    
    my $i = validation_schema(
            mixins => {
                default => {
                    required    => 1,
                    min_length  => 4,
                    max_length  => 255
                }
            },
            fields => {
                login => {
                    label => 'user login',
                    mixin => 'default',
                    validation => sub {
                        my ($self, $this, $params) = @_;
                        my ($name, $value) = ($this->{name}, $params->{login});
                        $self->error($this, "field $name must contain at least one letter and number")
                            if ($value !~ /[a-zA-Z]/ && $value !~ /[0-9]/);
                    }
                },
                password => {
                    mixin_field => 'login',
                    label => 'user password'
                }
            },
    );
    
    # Important, store the new instance created by the $i->setup function
    $o = $i->setup($params);
    
    unless ($o->validate) {
        return $o->errors
    }
    
=cut

our $PACKAGE = (caller)[0];
our $FIELDS  = $PACKAGE::fields = {};
our $MIXINS  = $PACKAGE::mixins = {};

sub new {
    shift  @_;
    return validation_schema(
        mixins => $MIXINS,
        fields => $FIELDS,
    )->setup(@_);
}

sub setup {
    my $class = shift;
    my $params = shift;
    my $self  = {};
    bless $self, $class;
    my $flds = $FIELDS;
    my $mixs = $MIXINS;
    $self->{params} = $params;
    $self->{fields} = $flds;
    $self->{mixins} = $mixs;
    $self->{errors} = [];
    
    # debugging - print Dumper($FIELDS); exit;
    
    # depreciated: 
    # die "No valid parameters were found, parameters are required for validation"
    #     unless $self->{params} && ref($self->{params}) eq "HASH";
    
    # validate mixin directives
    foreach (keys %{$self->{mixins}}) {
        $self->check_mixin($_, $self->{mixins}->{$_});
    }
    # validate field directives and create filters arrayref if needed
    foreach (keys %{$self->{fields}}) {
        $self->check_field($_, $self->{fields}->{$_}) unless $_ eq 'errors';
        unless ($_ eq 'errors') {
            if (! defined $self->{fields}->{$_}->{filters}) {
                $self->{fields}->{$_}->{filters} = [];
            }
        }
    }
    # check for and process a mixin directive
    foreach (keys %{$self->{fields}}) {
        unless ($_ eq 'errors') {
            
            $self->use_mixin($_, $self->{fields}->{$_}->{mixin})
                if $self->{fields}->{$_}->{mixin};
        }
    }
    # check for and process a mixin_field directive
    foreach (keys %{$self->{fields}}) {
        unless ($_ eq 'errors') {
            
            $self->use_mixin_field($self->{fields}->{$_}->{mixin_field}, $_)
                if $self->{fields}->{$_}->{mixin_field}
                && $self->{fields}->{$self->{fields}->{$_}->{mixin_field}};
        }
    }
    # check for and process input filters and default values
    foreach (keys %{$self->{fields}}) {
        unless ($_ eq 'errors') {
            
            tie my @filters, 'Array::Unique';
            @filters = @{$self->{fields}->{$_}->{filters}};
            
            if (defined $self->{fields}->{$_}->{filter}) {
                push @filters, $self->{fields}->{$_}->{filter};
                    delete $self->{fields}->{$_}->{filter};
            }
            
            $self->{fields}->{$_}->{filters} = [@filters];
            
            foreach my $filter (@{$self->{fields}->{$_}->{filters}}) {
                if (defined $self->{params}->{$_}) {
                    $self->basic_filter($filter, $_);
                }
            }
            
            # default values
            if (defined $self->{params}->{$_} && length($self->{params}->{$_}) == 0) {
                if ($self->{fields}->{$_}->{value}) {
                    $self->{params}->{$_} = $self->{fields}->{$_}->{value};
                }
            }
        }
    }
    return $self;
}



=method field

The field function defines the validation rules for the specified parameter it
is named after. e.g. field 'some_data' => {...}, validates against the value of 
the hash reference where the key is `some_data`.

    field 'some_param' => {
        mixin => 'default',
        validation => sub {
            my ($v, $this, $params) = @_;
            $v->error($this, "...")
                if ...
        }
    };

    Fields are comprised of specific directives, those directives are as follows:
    name: The name of the field (auto set)
    value: The value of the parameter matching the name of the field (auto set)
    mixin: The template to be used to copy directives from
    
    mixin 'template' => {
        required => 1
    };
    
    field 'a_field' => {
        mixin => 'template'
    }
    
    mixin_field: The field to be used as a mixin(template) to copy directives from
    
    field 'a_field' => {
        required => 1,
        min_length => 2,
        max_length => 10
    };
    
    field 'b_field' => {
        mixin_field => 'a_field'
    };
    
    validation: A validation routine that returns true or false
    
    field '...' => {
        validation => sub {
            my ($self, $field, $all_parameters) = @_;
            return 1
        }
    };
    
    errors: The collection of errors encountered during processing (auto set arrayref)
    label: An alias for the field name, something more human-readable
    error: A custom error message, displayed instead of the generic ones
    required : Determines whether the field is required or not, takes 1/0 true of false
    min_length: Determines the maximum length of characters allowed
    max_length: Determines the minimum length of characters allowed
    ref_type: Determines whether the field value is a valid perl reference variable
    regex: Determines whether the field value passed the regular expression test
    
    field 'c_field' => {
        label => 'a field labeled c',
        error => 'a field labeled c cannot ',
        required => 1,
        min_length => 2,
        max_length => 25,
        ref_type => 'array',
        regex => '^\d+$'
    };
    
    filter: An alias for the filters directive, see filter method for filter names
    filters: Set filters to manipulate the data before validation
    
    field 'd_field' => {
        ...,
        filters => [
            'trim',
            'strip'
        ]
    };
    
    field 'e_field' => {
        filter => 'strip'
    };
    
    field 'f_field' => {
        filters => [
            'trim',
            sub {
                $_[0] =~ s/(abc)|(123)//;
            }
        ]
    };
    
=cut

sub field {
    #my $group = shift if @_ == 3;
    my %spec = @_;
    if (%spec) {
        my $name = (keys(%spec))[0];
        my $data = (values(%spec))[0];
        
        #$name    = "$group:$name" if $group;
        
        #$FIELDS->{$name} = merge($data, $FIELDS->{$name});
        $FIELDS->{$name} = $data;
        
        $FIELDS->{$name}->{errors} = [];
        $FIELDS->{$name}->{validation} =
            defined $data->{validation} ? $data->{validation} : sub {0};
    }
    
    return 'field', %spec;
}

=method mixin

The mixin function defines validation rule templates to be later reused by
more specifically defined fields.

    mixin 'default' => {
        required    => 1,
        min_length  => 4,
        max_length  => 255
    };
    
=cut

sub mixin {
    my %spec = @_;
    if (%spec) {
        my $name = (keys(%spec))[0];
        my $data = (values(%spec))[0];
        
        #$MIXINS->{$name} = merge($data, $MIXINS->{$name});
        $MIXINS->{$name} = $data;
    }
    return 'mixin', %spec;
}

=method error

The error function is used to set and/or retrieve errors encountered or set
during validation. The error function with no parameters returns the error
message arrayref which can be used to output a single concatenated error message
a with delimeter.

    $self->error() # returns an arrayref of errors
    join '<br/>', @{$self->error()}; # html-break delimeted errors
    $self->error('some_param'); # show parameter-specific error messages arrayref
    $self->error($this, "$name must conform ..."); # set error, see `field` function
    
=cut

sub error {
    my ($self, @params) = @_;
    if (@params == 2) {
        # set error message
        my ($field, $error_msg) = @params;
        if (ref($field) eq "HASH" && (!ref($error_msg) && $error_msg)) {
            if (defined $self->{fields}->{$field->{name}}->{error}) {
                
                # temporary, may break stuff
                $error_msg = $self->{fields}->{$field->{name}}->{error};
                
                push @{$self->{fields}->{$field->{name}}->{errors}}, $error_msg unless
                    grep { $_ eq $error_msg } @{$self->{fields}->{$field->{name}}->{errors}};
                push @{$self->{errors}}, $error_msg unless
                    grep { $_ eq $error_msg } @{$self->{errors}};
            }
            else {
                push @{$self->{fields}->{$field->{name}}->{errors}}, $error_msg
                    unless grep { $_ eq $error_msg } @{$self->{fields}->{$field->{name}}->{errors}};
                push @{$self->{errors}}, $error_msg
                    unless grep { $_ eq $error_msg } @{$self->{errors}};
            }
        }
        else {
            die "Can't set error without proper field and error message data, " .
            "field must be a hashref with name and value keys";
        }
    }
    elsif (@params == 1) {
        # return param-specific errors
        return $self->{fields}->{$params[0]}->{errors};
    }
    else {
        # return all errors
        return $self->{errors};
    }
    return 0;
}

=method errors

The errors function is a synonym for the error function.

=cut

sub errors {
    my ($self, @args) = @_;
    return $self->error(@args);
}

=method check_mixin

The check_mixin function is used internally to validate the defined keys and
values of mixins.

=cut

sub check_mixin {
    my ($self, $mixin, $spec) = @_;
    
    my $directives = {
        required    => sub {1},
        min_length  => sub {1},
        max_length  => sub {1},
        data_type   => sub {1},
        ref_type    => sub {1},
        regex       => sub {1},
        
        filter      => sub {1},
        filters     => sub {1},
        
    };
    
    foreach (keys %{$spec}) {
        if (!defined $directives->{$_}) {
            die "The `$_` directive supplied by the `$mixin` mixin is not supported";
        }
        if (!$directives->{$_}->()) {
            die "The `$_` directive supplied by the `$mixin` mixin is invalid";
        }
    }
    
    return 1;
}

=method check_field

The check_field function is used internally to validate the defined keys and
values of fields.

=cut

sub check_field {
    my ($self, $field, $spec) = @_;
    
    my $directives = {
        mixin       => sub {1},
        mixin_field => sub {1},
        validation  => sub {1},
        errors      => sub {1},
        label       => sub {1},
        error       => sub {1},
        value       => sub {1},
        name        => sub {1},
        filter      => sub {1},
        filters     => sub {1},
        
        required    => sub {1},
        min_length  => sub {1},
        max_length  => sub {1},
        data_type   => sub {1},
        ref_type    => sub {1},
        regex       => sub {1},
    };
    
    foreach (keys %{$spec}) {
        if (!defined $directives->{$_}) {
            die "The `$_` directive supplied by the `$field` field is not supported";
        }
        if (!$directives->{$_}->()) {
            die "The `$_` directive supplied by the `$field` field is invalid";
        }
    }
    
    return 1;
}

=method use_mixin

The use_mixin function sequentially applies defined mixin parameteres
(as templates)to the specified field.

=cut

sub use_mixin {
    my ($self, $field, $mixin_s ) = @_;
    if (ref($mixin_s) eq "ARRAY") {
        foreach my $mixin (@{$mixin_s}) {
            if (defined $self->{mixins}->{$mixin}) {
                $self->{fields}->{$field} =
                    merge($self->{fields}->{$field}, $self->{mixins}->{$mixin});
            }
        }
    }
    else {
        if (defined $self->{mixins}->{$mixin_s}) {
            $self->{fields}->{$field} =
                merge($self->{fields}->{$field}, $self->{mixins}->{$mixin_s});
        }
    }
    return 1;
}

=method use_mixin_field

The use_mixin_field function copies the properties (directives) of a specified
field to the target field processing copied mixins along the way.

=cut

sub use_mixin_field {
    my ($self, $field, $target) = @_;
    $self->check_field($field, $self->{fields}->{$field});
    
    # name and label overwrite restricted
    my $name  = $self->{fields}->{$target}->{name}
        if defined $self->{fields}->{$target}->{name};
    my $label = $self->{fields}->{$target}->{label}
        if defined $self->{fields}->{$target}->{label};
    
    $self->{fields}->{$target} =
        merge($self->{fields}->{$field}, $self->{fields}->{$target});
        
    $self->{fields}->{$target}->{name}  = $name  if defined $name;
    $self->{fields}->{$target}->{label} = $label if defined $label;
    
    while (my($key, $val) = each (%{$self->{fields}->{$field}})) {
        if ($key eq 'mixin') {
            $self->use_mixin($target, $key);
        }
    }
    return 1;
}

=method validate

The validate function sequentially checks the passed-in field names against their
defined validation rules and returns 0 or 1 based on the existence of errors.

=cut

sub validate {
    my ($self, @fields) = @_;
    
    # translation (mainly for param => group:field operation)
    my $original_parameters = undef;
    
    if ("HASH" eq ref $fields[0]) {
        my $map = $fields[0];
        $original_parameters = $self->{params}; @fields = ();
        foreach my $param (keys %{$map}) {
            my $param_value = $self->{params}->{$param};
            delete $self->{params}->{$param};
            $self->{params}->{$map->{$param}} = $param_value;
            push @fields, $map->{$param};
        }
    }
    
    if ($self->{params}) {
        if (!@fields) {
            # process all params
            foreach my $field (keys %{$self->{params}}) {
                if (!defined $self->{fields}->{$field}) {
                    die "Data validation field `$field` does not exist";
                }
                my $this = $self->{fields}->{$field};
                $this->{name} = $field;
                $this->{value} = $self->{params}->{$field};
                my @passed = (
                    $self,
                    $this,
                    $self->{params}
                );
                # execute simple validation
                $self->basic_validate($field, $this);
                # custom validation
                $self->{fields}->{$field}->{validation}->(@passed);
            }
        }
        else {
            foreach my $field (@fields) {
                if (!defined $self->{fields}->{$field}) {
                    die "Data validation field `$field` does not exist";
                }
                my $this = $self->{fields}->{$field};
                $this->{name} = $field;
                $this->{value} = $self->{params}->{$field};
                my @passed = (
                    $self,
                    $this,
                    $self->{params}
                );
                # execute simple validation
                $self->basic_validate($field, $this);
                # custom validation
                $self->{fields}->{$field}->{validation}->(@passed);
            }
        }
    }
    else {
        if (@fields) {
            foreach my $field (@fields) {
                if (!defined $self->{fields}->{$field}) {
                    die "Data validation field `$field` does not exist";
                }
                my $this = $self->{fields}->{$field};
                $this->{name} = $field;
                $this->{value} = $self->{params}->{$field};
                my @passed = (
                    $self,
                    $this,
                    $self->{params}
                );
                # execute simple validation
                $self->basic_validate($field, $this);
                # custom validation
                $self->{fields}->{$field}->{validation}->(@passed)
                    if $self->{fields}->{$field}->{value};
            }
        }
        # if no parameters are found, instead of dying, warn and continue
        elsif (!$self->{params} || ref($self->{params}) ne "HASH") {
            # warn
            #     "No valid parameters were found, " .
            #     "parameters are required for validation";
            foreach my $field (keys %{$self->{fields}}) {
                my $this = $self->{fields}->{$field};
                $this->{name}  = $field;
                $this->{value} = $self->{params}->{$field};
                # execute simple validation
                $self->basic_validate($field, $this);
                # custom validation shouldn't fire without params and data
                # my @passed = ($self, $this, {});
                # $self->{fields}->{$field}->{validation}->(@passed);
            }
        }
        #default - probably unneccessary
        else {
            foreach my $field (keys %{$self->{fields}}) {
                my $this = $self->{fields}->{$field};
                $this->{name}  = $field;
                $this->{value} = $self->{params}->{$field};
                # execute simple validation
                $self->basic_validate($field, $this);
                # custom validation shouldn't fire without params and data
                # my @passed = ($self, $this, {});
                # $self->{fields}->{$field}->{validation}->(@passed);
            }
        }
    }
    
    $self->{params} = $original_parameters;
    
    return @{$self->{errors}} ? 0 : 1; # returns true if no errors
}

=method basic_validate

The basic_validate function processes the pre-defined contraints e.g.,
required, min_length, max_length, etc.

=cut

sub basic_validate {
    my ($self, $field, $this) = @_;
    
    # does field have a label, if not use field name
    my $name  = $this->{label} ? $this->{label} : "parameter `$field`";
    my $value = $this->{value};
    
    # check if required
    if ($this->{required} && (! defined $value || $value eq '')) {
        my $error = defined $this->{error} ? $this->{error} : "$name is required";
        $self->error($this, $error);
        return 1; # if required and fails, stop processing immediately
    }
    
    if ($this->{required} || $value) {
    
        # check min character length
        if (defined $this->{min_length}) {
            if ($this->{min_length}) {
                if (length($value) < $this->{min_length}){
                    my $error = defined $this->{error} ? $this->{error} :
                    "$name must contain at least " .
                        $this->{min_length} .
                        (int($this->{min_length}) > 1 ?
                         " characters" : " character");
                    $self->error($this, $error);
                }
            }
        }
        
        # check max character length
        if (defined $this->{max_length}) {
            if ($this->{max_length}) {
                if (length($value) > $this->{max_length}){
                    my $error = defined $this->{error} ? $this->{error} :
                    "$name cannot be greater than " .
                        $this->{max_length} .
                        (int($this->{max_length}) > 1 ?
                         " characters" : " character");
                    $self->error($this, $error);
                }
            }
        }
        
        # check reference type
        if (defined $this->{ref_type}) {
            if ($this->{ref_type}) {
                unless (lc(ref($value)) eq lc($this->{ref_type})) {
                    my $error = defined $this->{error} ? $this->{error} :
                    "$name is not being stored as " .
                        ($this->{ref_type} =~ /^[Aa]/ ? "an " : "a ") . 
                            $this->{ref_type} . " reference";
                    $self->error($this, $error);
                }
            }
        }
        
        # check data type
        if (defined $this->{data_type}) {
            if ($this->{data_type}) {
                
            }
        }
        
        # check against regex
        if (defined $this->{regex}) {
            if ($this->{regex}) {
                unless ($value =~ $this->{regex}) {
                    my $error = defined $this->{error} ? $this->{error} :
                    "$name failed regular expression testing " .
                        "using `$value`";
                    $self->error($this, $error);
                }
            }
        }
    }
    return 1;
}

=method basic_filter

The basic_filter function processes the pre-defined filters e.g.,
trim, strip, digit, alpha, numeric, alphanumeric, uppercase, lowercase,
titlecase, or custom etc.

=cut

sub basic_filter {
    my ($self, $filter, $field) = @_;
    
    # convert to lowercase
    if ($filter eq "lowercase") {
        if (defined $self->{params}->{$field}) {
            $self->{params}->{$field} =
                lc $self->{params}->{$field};
        }
    }
    # convert to uppercase
    if ($filter eq "uppercase") {
        if (defined $self->{params}->{$field}) {
            $self->{params}->{$field} =
                uc $self->{params}->{$field};
        }
    }
    # convert to camelcase
    if ($filter eq "camelcase") {
        if (defined $self->{params}->{$field}) {
            $self->{params}->{$field} =
                join " ", map (ucfirst, split (/\s/, lc($self->{params}->{$field})));
        }
    }
    # convert to titlecase
    if ($filter eq "titlecase") {
        if (defined $self->{params}->{$field}) {
            $self->{params}->{$field} =
                join " ", map (ucfirst, split (/\s/, $self->{params}->{$field}));
        }
    }
    # convert to alphanumeric
    if ($filter eq "alphanumeric") {
        if (defined $self->{params}->{$field}) {
            $self->{params}->{$field} =~
                s/[^A-Za-z0-9]//g;
        }
    }
    # convert to numeric
    if ($filter eq "numeric") {
        if (defined $self->{params}->{$field}) {
            $self->{params}->{$field} =~
                s/[^0-9]//g;
        }
    }
    # convert to alpha
    if ($filter eq "alpha") {
        if (defined $self->{params}->{$field}) {
            $self->{params}->{$field} =~
                s/[^A-Za-z]//g;
        }
    }
    # convert to digit
    if ($filter eq "digit") {
        if (defined $self->{params}->{$field}) {
            $self->{params}->{$field} =~
                s/\D//g;
        }
    }
    # convert to strip
    if ($filter eq "strip") {
        if (defined $self->{params}->{$field}) {
            $self->{params}->{$field} =~
                s/\s+/ /g;
        }
    }
    # convert to trim
    if ($filter eq "trim") {
        if (defined $self->{params}->{$field}) {
            $self->{params}->{$field} =~
                s/^\s+//g;
            $self->{params}->{$field} =~
                s/\s+$//g;
        }
    }
    # use regex
    if ($filter =~ "^CODE") {
        if (defined $self->{params}->{$field}) {
            $filter->($self->{params}->{$field});
        }
    }
    
}

=method validation_schema

The validation_schema method encapsulates fields and mixins and returns a
Validation::Class instance for further validation. This method exist for situations
where Validation::Class is use outside of a specific validation package.

    my $i = validation_schema(
            mixins => {
                    'default' => {
                            required => 1
                    }
            },
            fields => {
                    'test1' => {
                            mixin => 'default'
                    }
            },
    );
    
    # Important store the new instance
    $o = $i->setup({ test1 => '...' });
    
    if ($o->validate('test1')) {
        ...
    }

=cut

sub validation_schema {
    my %properties = @_;
    my $KEY  = undef;
       $KEY .= (@{['A'..'Z',0..9]}[rand(36)]) for (1..5);
    $PACKAGE = "Validation::Class::Instance::" . $KEY;
    
    my $code = "package $PACKAGE; use Validation::Class qw/:all/; our \$PACKAGE = '$PACKAGE'; ";
    $code .= "our \$FIELDS  = \$PACKAGE::fields = {}; ";
    $code .= "our \$MIXINS  = \$PACKAGE::mixins = {}; ";
    
    # fix load priority mixin, then field
    
    while (my($key, $value) = each(%properties)) {
        die "$key is not a supported property"
            unless $key eq 'mixins' || $key eq 'fields';
        if ($key eq 'mixins') {
            while (my($key, $value) = each(%{$properties{mixins}})) {
                $code .= "mixin('" . $key . "'," . Dumper($value) . ");";
            }
        }
    }
    
    while (my($key, $value) = each(%properties)) {
        die "$key is not a supported property"
            unless $key eq 'mixins' || $key eq 'fields';
        if ($key eq 'fields') {
            while (my($key, $value) = each(%{$properties{fields}})) {
                $code .= "field('" . $key . "'," . Dumper($value) . ");";
            }
        }
    } $code .= "1;";
    
    #while (my($key, $value) = each(%properties)) {
    #    die "$key is not a supported property"
    #        unless $key eq 'mixins' || $key eq 'fields';
    #    if ($key eq 'mixins') {
    #        while (my($key, $value) = each(%{$properties{mixins}})) {
    #            $code .= "mixin('" . $key . "'," . Dumper($value) . ");";
    #        }
    #    }
    #    if ($key eq 'fields') {
    #        while (my($key, $value) = each(%{$properties{fields}})) {
    #            $code .= "field('" . $key . "'," . Dumper($value) . ");";
    #        }
    #    }
    #} $code .= "1;";
    
    eval $code or die $@;
    return $PACKAGE;
}

1; # End of Validation::Class
