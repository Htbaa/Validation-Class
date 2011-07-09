package Validation::Class;

# ABSTRACT: Centralized Input Validation For Any Application

use strict;
use warnings;
use 5.008001;
use Moose;
use Moose::Exporter;
use Array::Unique;
# use Hash::Merge;

    Moose::Exporter->setup_import_methods(
        as_is  => [ 'field', 'filter', 'mixin' ],
        also   => 'Moose',
    );

our $FIELDS  = {};
our $MIXINS  = {};
our $FILTERS = { # default filters
    trim => sub {
        $_[0] =~ s/^\s+//g;
        $_[0] =~ s/\s+$//g;
        $_[0];
    },
    alpha => sub {
        $_[0] =~ s/[^A-Za-z]//g;
        $_[0];
    },
    digit => sub {
        $_[0] =~ s/\D//g;
        $_[0];
    },
    whiteout => sub {
        $_[0] =~ s/\s+/ /g;
        $_[0];
    },
    numeric => sub {
        $_[0] =~ s/[^0-9]//g;
        $_[0];
    },
    uppercase => sub {
        uc $_[0];
    },
    titlecase => sub {
        join( "", map ( ucfirst, split( /\s/, $_[0] ) ) );
    },
    camelcase => sub {
        join( "", map ( ucfirst, split( /\s/, lc $_[0] ) ) );
    },
    lowercase => sub {
        lc $_[0];
    },
    alphanumeric => sub {
        $_[0] =~ s/[^A-Za-z0-9]//g;
        $_[0];
    }
};

=head1 SYNOPSIS

    use MyApp::Validation;
    
    my $input = MyApp::Validation->new(params => $params);
    
    unless ($input->validate){
        return $input->errors->to_string;
    }

=head1 DESCRIPTION

Validation::Class is a different approach to data validation, it attempts to
simplify and centralize data validation rules to ensure DRY (don't repeat
yourself) code. The primary intent of this module is to provide a simplistic
validation work-flow and promote code (validation) reuse.

=head1 BUILDING A VALIDATION CLASS

    package MyApp::Validation;
    
    use Validation::Class qw/field mixin filter/;
    use base 'Validation::Class';
    
    # a validation rule
    field 'login'  => {
        label      => 'user login',
        error      => 'login invalid',
        validation => sub {
            my ($self, $this, $fields) = @_;
            return $this->{value} eq 'admin' ? 1 : 0;
        }
    };
    
    # a validation rule
    field 'password'  => {
        label         => 'user password',
        error         => 'password invalid',
        validation    => sub {
            my ($self, $this, $fields) = @_;
            return $this->{value} eq 'pass' ? 1 : 0;
        }
    };
    
    1;

=cut

=head1 USING DIRECTIVES

    package MyApp::Validation;
    
    use Validation::Class qw/field mixin/;
    use base 'Validation::Class';
    
    # a validation template
    mixin '...'  => {
        ...
    };
    
    # a validation rule
    field '...'  => {
        mixin => '...',
        ...
    };
    
    1;
    
When building a validation class, the first encountered and arguably two most
important keyword functions are field() and mixin() which are used to declare
their respective properties. A mixin() declares a validation template where
its properties are intended to be copied within field() declarations which
declares validation rules and properties.

Both the field() and mixin() declarations/functions require two parameters, the
first being a name, used to identify the declaration, and the second being a
hashref of key/value pairs. The key(s) within a declaration are commonly referred
to as directives.

The following is a list of default directives which can be used in field/mixin
declarations:

=cut

our $DIRECTIVES = {};

=head2 label

    # the label directive
    field 'foobar'  => {
        label => 'Foo Bar',
        ...
    };

=cut

$DIRECTIVES->{label} = {
    mixin => 0,
    field => 1,
    multi => 0
};

=head2 alias

    # the alias directive
    field 'foobar'  => {
        alias => 'foo_bar',
        ...
    };

=cut

$DIRECTIVES->{alias} = {
    mixin => 0,
    field => 1,
    multi => 1
};

=head2 mixin

    mixin 'abcxyz' => {
        ...
    };

    # the mixin directive
    field 'foobar'  => {
        mixin => 'abcxyz',
        ...
    };

=cut

$DIRECTIVES->{mixin} = {
    mixin => 0,
    field => 1,
    multi => 1
};

=head2 mixin_field

    # the mixin_field directive
    field 'foobar'  => {
        mixin_field => '...',
        ...
    };

=cut

$DIRECTIVES->{mixin_field} = {
    mixin => 0,
    field => 1,
    multi => 1
};

=head2 validation

    # the validation directive
    field 'foobar'  => {
        validation => '...',
        ...
    };

=cut

$DIRECTIVES->{validation} = {
    mixin => 0,
    field => 1,
    multi => 0
};

=head2 error/errors

    # the error(s) directive
    field 'foobar'  => {
        errors => '...',
        ...
    };

=cut

$DIRECTIVES->{errors} = {
    mixin => 0,
    field => 1,
    multi => 0
};

$DIRECTIVES->{error} = $DIRECTIVES->{errors};

=head2 value

    # the value directive
    field 'foobar'  => {
        value => '...',
        ...
    };

=cut

$DIRECTIVES->{value} = {
    mixin => 1,
    field => 1,
    multi => 1
};

=head2 name

    # the name directive
    field 'foobar'  => {
        name => '...',
        ...
    };

=cut

$DIRECTIVES->{name} = {
    mixin => 0,
    field => 0,
    multi => 0
};

=head2 filter/filters

    # the filter(s) directive
    field 'foobar'  => {
        filter => '...',
        ...
    };

=cut

$DIRECTIVES->{filter} = {
    mixin => 1,
    field => 1,
    multi => 1
};

$DIRECTIVES->{filters} = $DIRECTIVES->{filter};

=head2 required

    # the required directive
    field 'foobar'  => {
        required => '...',
        ...
    };

=cut

$DIRECTIVES->{required} = {
    mixin => 1,
    field => 1,
    multi => 0
};

=head1 USING VALIDATOR DIRECTIVES

    package MyApp::Validation;
    
    use Validation::Class qw/field mixin/;
    use base 'Validation::Class';
    
    # a validation rule with validator directives
    field '...'  => {
        min_length => '...',
        max_length => '...',
        pattern    => '+# (###) ###-####',
        ...
    };
    
    1;
    
Validator directives are special directives with associated validation code that
is used to validate common use-cases such as "checking the length of a parameter",
etc.

The following is a list of the default validators which can be used in field/mixin
declarations:

=cut

=head2 min_length

    # the min_length directive
    field 'foobar'  => {
        min_length => '...',
        ...
    };

=cut

$DIRECTIVES->{min_length} = {
    mixin     => 1,
    field     => 1,
    multi     => 0,
    validator => sub {
        my ( $directive, $value, $field, $class ) = @_;
        if ($value) {
            unless ( length($value) > $directive ) {
                my $handle = $field->{label} || $field->{name};
                my $characters = int( $directive ) > 1 ?
                    " characters" : " character";
                my $error = "$handle must contain $directive or more $characters";
                $class->error( $field, $error );
                return 0;
            }
        }
        return 1;
    }
};

=head2 max_length

    # the max_length directive
    field 'foobar'  => {
        max_length => '...',
        ...
    };

=cut

$DIRECTIVES->{max_length} = {
    mixin     => 1,
    field     => 1,
    multi     => 0,
    validator => sub {
        my ( $directive, $value, $field, $class ) = @_;
        if ($value) {
            unless ( length($value) < $directive ) {
                my $handle = $field->{label} || $field->{name};
                my $characters = int( $directive ) > 1 ?
                    " characters" : " character";
                my $error = "$handle must contain $directive or less $characters";
                $class->error( $field, $error );
                return 0;
            }
        }
        return 1;
    }
};

=head2 between

    # the between directive
    field 'foobar'  => {
        between => '1-5',
        ...
    };

=cut

$DIRECTIVES->{between} = {
    mixin     => 1,
    field     => 1,
    multi     => 0,
    validator => sub {
        my ($directive, $value, $field, $class) = @_;
        my ($min, $max) = split /\-/, $directive;
        if ($value) {
            unless ($value > $min && $value < $max) {
                my $handle = $field->{label} || $field->{name};
                $class->error($field, "$handle must be between $directive");
                return 0;
            }
        }
        return 1;
    }
};

=head2 pattern

    # the pattern directive
    field 'telephone'  => {
        pattern => '### ###-####',
        ...
    };
    
    field 'country_code'  => {
        pattern => 'XX',
        filter  => 'uppercase'
        ...
    };

=cut

$DIRECTIVES->{pattern} = {
    mixin     => 1,
    field     => 1,
    multi     => 0,
    validator => sub {
        my ( $directive, $value, $field, $class ) = @_;
        if ($value) {
            # build the regex
            my $regex = $directive;
            $regex =~ s/([^#X ])/\\$1/g;
            $regex =~ s/#/\\d/g;
            $regex =~ s/X/[a-zA-Z]/g;
            $regex = qr/$regex/;
            unless ( $value =~ $regex ) {
                my $handle = $field->{label} || $field->{name};
                my $error = "$handle does not match the pattern $directive";
                $class->error( $field, $error );
                return 0;
            }
        }
        return 1;
    }
};

# mixin/field types store
has 'directives' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { $DIRECTIVES }
);

=head1 USING MIXINS AND GROUPING

    package MyApp::Validation;
    
    use Validation::Class qw/field mixin filter/;
    use base 'Validation::Class';
    
    # a validation rule template
    mixin 'basic'  => {
        required   => 1,
        min_length => 1,
        max_length => 255,
        filters    => ['lowercase', 'alphanumeric']
    };
    
    # a validation rule
    field 'user:login'  => {
        mixin      => 'basic',
        label      => 'user login',
        error      => 'login invalid',
        validation => sub {
            my ($self, $this, $fields) = @_;
            return $this->{value} eq 'admin' ? 1 : 0;
        }
    };
    
    # a validation rule
    field 'user:password'  => {
        mixin         => 'basic',
        label         => 'user login',
        error         => 'login invalid',
        validation    => sub {
            my ($self, $this, $fields) = @_;
            return $this->{value} eq 'pass' ? 1 : 0;
        }
    };
    
    1;

=head2 FIELD KEYWORD

The field keyword create a validation block and defines validation rules for
reuse in code. The field keyword should correspond with the parameter name
expected to be passed to your validation class.

    package MyApp::Validation;
    use Validation::Class qw/field mixin filter/;
    use base 'Validation::Class';
    
    field 'login' => {
        required   => 1,
        min_length => 1,
        max_length => 255,
        ...
    };
    
The field keword takes two arguments, the field name and a hashref of key/values
pairs. The keys are referred to as directives, those directives are as follows:

=head3 name

The name of the field (auto set)

=head3 value

The value of the parameter matching the name of the field (auto set)

=head3 mixin

The template to be used to copy directives from e.g.
    
    mixin 'template' => {
        required => 1
    };
    
    field 'a_field' => {
        mixin => 'template'
    }
    
=head3 mixin_field

The field to be used as a mixin (template) to have directives copied from e.g.
    
    field 'a_field' => {
        required => 1,
        min_length => 2,
        max_length => 10
    };
    
    field 'b_field' => {
        mixin_field => 'a_field'
    };
    
=head3 validation

A custom validation routine. Please note that the return value is not important.
Please register an error if validation fails e.g.
    
    field '...' => {
        validation => sub {
            my ($self, $this, $parameters) = @_;
            $self->error($this, "I failed") if $parameters->{something};
        }
    };
    
=head3 errors

The collection of errors encountered during processing (auto set arrayref)

=head3 label

An alias for the field name, something more human-readable, is also used in
auto-generated error messages

=head3 error

A custom error message, displayed instead of the generic ones

=head3 required

Determines whether the field is required or not, takes 1 or 0

=head3 min_length

Determines the minimum length of characters allowed

=head3 max_length

Determines the maximum length of characters allowed

=head3 alias

Defines alternative parameter names for the field to be matched against
    
    field 'c_field' => {
        label => 'a field labeled c',
        error => 'a field labeled c cannot be ...',
        required => 1,
        min_length => 2,
        max_length => 25,
        alais => 'cf'
    };
    
=head3 filter

An alias for the filters directive

=head3 filters

Set filters to manipulate the data before validation, e.g.
    
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
    
    # the following filters can be set using the filter(s) keywords:
    
    field 'g_field' => {
        filters => [
            'trim', 
            'alpha',
            'digit',
            'strip',
            'numeric ',
            'lowercase',
            'uppercase',
            'titlecase',
            'camelcase',
            'lowercase',
            'alphanumeric',
            sub {
                my $value = shift;
            }
        ]
    };

=cut

sub field {
    my %spec = @_;

    if (%spec) {
        my $name = ( keys(%spec) )[0];
        my $data = ( values(%spec) )[0];

        $FIELDS->{$name} = $data;
        $FIELDS->{$name}->{errors} = [];
    }

    return 'field', %spec;
}

=head2 MIXIN KEYWORD

The mixin keyword creates a validation rules template that can be applied to any
field using the mixin directive.

    package MyApp::Validation;
    use Validation::Class qw/field mixin/;
    use base 'Validation::Class';
    
    mixin 'constrain' => {
        required   => 1,
        min_length => 1,
        max_length => 255,
        ...
    };
    
    field 'login' => {
        mixin => 'constrain',
        ...
    };

=cut

sub mixin {
    my %spec = @_;

    if (%spec) {
        my $name = ( keys(%spec) )[0];
        my $data = ( values(%spec) )[0];

        $MIXINS->{$name} = $data;
    }

    return 'mixin', %spec;
}

=head2 FILTER KEYWORD

The filter keyword creates custom filters to be used in your field definitions.

    package MyApp::Validation;
    use Validation::Class qw/field filter/;
    use base 'Validation::Class';
    
    filter 'telephone' => sub {
        ...
    };
    
    field 'telephone' => {
        filter => ['trim', 'telephone'],
        ...
    };

=cut

sub filter {
    my ($name, $data) = @_;

    if ($name && $data) {
        $FILTERS->{$name} = $data;
    }

    return 'filter', @_;
}

=head2 DIRECTIVE KEYWORD

The directive keyword creates custom validator directives to be used in your field
definitions. The routine is passed two parameters, the value of directive and the
value of the field the validator is being processed against. The validator should
return true or false.

    package MyApp::Validation;
    use Validation::Class qw/directive field/;
    use base 'Validation::Class';
    
    directive 'between' => sub {
        my ($directive, $value, $field, $class) = @_;
        my ($min, $max) = split /\-/, $directive;
        unless ($value > $min && $value < $max) {
            my $handle = $field->{label} || $field->{name};
            $class->error($field, "$handle must be between $directive");
            return 0;
        }
        return 1;
    };
    
    field 'hours' => {
        between => '00-24',
        ...
    };

=cut

sub directive {
    my ($name, $data) = @_;

    if ($name && $data) {
        $DIRECTIVES->{$name} = {
            mixin     => 1,
            field     => 1,
            validator => $data
        };
    }

    return 'directive', @_;
}


=head1 EXECUTING A VALIDATION CLASS

The following is an example of how to use you constructed validation class in
other code, .e.g. Web App Controller, etc.

    use MyApp::Validation;
    
    my $input = MyApp::Validation->new(params => $params);
    unless ($input->validate('field1','field2')){
        return $input->errors->to_string;
    }
    
Feeling lazy, have your validation class automatically find the appropriate fields
to validate against (params must match field names).

    use MyApp::Validation;
    
    my $input = MyApp::Validation->new(params => $params);
    unless ($input->validate){
        return $input->errors->to_string;
    }
    
If you are using groups in your validation class you might validate your data
like so ...

    use MyApp::Validation;
    
    my $input = MyApp::Validation->new(params => $params);
    unless ($input->validate('user:login', 'user:password')){
        return $input->errors->to_string;
    }
    
Although this means that the incoming parameters need to specify its parameter
names using the same group naming convention. If this is not to your liking,
the validate() method can assist you in mapping your incoming parameters to your
grouped validation fields as shown here:

    use MyApp::Validation;
    
    my $input = MyApp::Validation->new(params => $params);
    unless ($input->validate({ user => 'user:login', pass => 'user:password')){
        return $input->errors->to_string;
    }
    
You can also map automatically by using field aliases whereby a field definition
will have an alias attribute containing an arrayref of alternate parameters that
can be matched against passed-in parameters as an alternative to the parameter
mapping technique. The whole mapping technique can get cumbersome in larger
projects.

    package MyApp::Validation;
    
    field 'foo:bar' => {
        ...,
        alias => [
            'foo',
            'bar',
            'baz',
            'bax'
        ]
    };

    use MyApp::Validation;
    
    my  $input = MyApp::Validation->new(params => { foo => 1 });
    unless ($input->validate(){
        return $input->errors->to_string;
    }

=cut

=head2 new

The new method instantiates and returns an instance of your validation class.

    use MyApp::Validation;
    
    my $input = MyApp::Validation->new;
    $input->params($params);
    ...
    
or
    
    my $input = MyApp::Validation->new(params => $params);
    ...

=cut

# tie it all together after instantiation
sub BUILD {
    my $self = shift;

    # add custom filters
    foreach my $filter (keys %{$FILTERS}) {
        unless (defined $self->filters->{$filter}) {
            $self->filters->{$filter} = $FILTERS->{$filter};
        }
    }

    # validate mixin directives
    foreach ( keys %{ $self->mixins } ) {
        $self->check_mixin( $_, $self->mixins->{$_} );
    }

    # validate field directives and create filters arrayref if needed
    foreach ( keys %{ $self->fields } ) {
        $self->check_field( $_, $self->fields->{$_} ) unless $_ eq 'errors';
        unless ( $_ eq 'errors' ) {
            if ( !defined $self->fields->{$_}->{filters} ) {
                $self->fields->{$_}->{filters} = [];
            }
        }
    }

    # check for and process a mixin directive
    foreach ( keys %{ $self->fields } ) {
        unless ( $_ eq 'errors' ) {

            $self->use_mixin( $_, $self->fields->{$_}->{mixin} )
              if $self->fields->{$_}->{mixin};
        }
    }

    # check for and process a mixin_field directive
    foreach ( keys %{ $self->fields } ) {
        unless ( $_ eq 'errors' ) {

            $self->use_mixin_field( $self->fields->{$_}->{mixin_field}, $_ )
              if $self->fields->{$_}->{mixin_field}
                  && $self->fields->{ $self->fields->{$_}->{mixin_field} };
        }
    }

    # check for and process input filters and default values
    foreach ( keys %{ $self->fields } ) {
        unless ( $_ eq 'errors' ) {

            tie my @filters, 'Array::Unique';
            @filters = @{ $self->fields->{$_}->{filters} };

            if ( defined $self->fields->{$_}->{filter} ) {
                push @filters, $self->fields->{$_}->{filter};
                delete $self->fields->{$_}->{filter};
            }

            $self->fields->{$_}->{filters} = [@filters];

            foreach my $filter ( @{ $self->fields->{$_}->{filters} } ) {
                if ( defined $self->params->{$_} ) {
                    $self->use_filter( $filter, $_ );
                }
            }

            # default values
            if ( defined $self->params->{$_}
                && length( $self->params->{$_} ) == 0 )
            {
                if ( $self->fields->{$_}->{value} ) {
                    $self->params->{$_} = $self->fields->{$_}->{value};
                }
            }
        }
    }
    
    # alias checking, ... for duplicate aliases, etc
    my $fieldtree = {};
    my $aliastree = {};
    foreach my $field (keys %{$self->fields}) {
        $fieldtree->{$field} = $field;
        my $f = $self->fields->{$field};
        if (defined $f->{alias}) {
            my $aliases = "ARRAY" eq ref $f->{alias} ?
                $f->{alias} : [$f->{alias}];
            
            foreach my $alias (@{$aliases}) {
                if ($aliastree->{$alias}) {
                    die "The field $field contains the alias $alias which is ".
                        "also defined in the field $aliastree->{$alias}";
                }
                elsif ($fieldtree->{$alias}) {
                    die "The field $field contains the alias $alias which is ".
                        "the name of an existing field";
                }
                else {
                    $aliastree->{$alias} = $field;
                }
            }
        }
    }
    undef $aliastree;

    return $self;
};

=head2 fields

The fields attribute returns a hashref of defined fields, filtered and merged with
thier parameter counterparts.

    my $fields = $self->fields();
    ...

=cut

# validation rules store
has 'fields' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { $FIELDS }
);

=head2 filters

The filters attribute returns a hashref of pre-defined filter definitions.

    my $filters = $self->filters();
    
    $filters->{trim}->(...);
    $filters->{alpha}->(...);
    $filters->{digit}->(...);
    $filters->{whiteout}->(...);
    $filters->{numeric}->(...);
    $filters->{uppercase}->(...);
    $filters->{titlecase}->(...);
    $filters->{camelcase}->(...);
    $filters->{lowercase}->(...);
    $filters->{alphanumeric}->(...);
    ...

=cut

# mixin/field types store
has 'filters' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { $FILTERS }
);

=head2 ignore_unknown

The ignore_unknown boolean determines whether your application will live or die
upon encountering unregistered fields during validation.

    MyApp::Validation->new(params => $params, ignore_unknown => 1);
    
    or
    
    $self->ignore_unknown(1);
    ...

=cut

# ignore unknown input parameters
has 'ignore_unknown' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0
);

=head2 report_unknown

The report_unknown boolean determines whether your application will report
unregistered fields as class-level errors upon encountering unregistered fields
during validation.

    MyApp::Validation->new(params => $params,
    ignore_unknown => 1, report_unknown => 1);
    
    or
    
    $self->report_unknown(1);
    ...

=cut

# report unknown input parameters
has 'report_unknown' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0
);

=head2 params

The params attribute gets/sets the parameters to be validated.

    my $input = {
        ...
    };
    
    $self->params($input);
    my $params = $self->params();
    
    ...

=cut

# input parameters store
has 'params' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} }
);

=head2 mixins

The mixins attribute returns a hashref of defined validation templates.

    my $mixins = $self->mixins();
    ...

=cut

# validation rules templates store
has 'mixins' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { $MIXINS }
);

# mixin/field directives store
has 'types' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        
        my  $types = {
            mixin => {},
            field => {}
        };
        
        foreach my $directive (keys %{ $DIRECTIVES }) {
            $types->{mixin}->{$directive} = $DIRECTIVES->{$directive}
                if $DIRECTIVES->{$directive}->{mixin};
            $types->{field}->{$directive} = $DIRECTIVES->{$directive}
                if $DIRECTIVES->{$directive}->{field};
        }
        
        return $types;
    }
);

sub check_mixin {
    my ( $self, $mixin, $spec ) = @_;

    my $directives = $self->types->{mixin};

    foreach ( keys %{$spec} ) {
        if ( ! defined $directives->{$_} ) {
            die
              "The $_ directive supplied by the $mixin mixin is not supported";
        }
        if ( ! $directives->{$_} ) {
            die "The $_ directive supplied by the $mixin mixin is invalid";
        }
    }

    return 1;
}

sub check_field {
    my ( $self, $field, $spec ) = @_;

    my $directives = $self->types->{field};

    foreach ( keys %{$spec} ) {
        if ( ! defined $directives->{$_} ) {
            die
              "The $_ directive supplied by the $field field is not supported";
        }
    }

    return 1;
}

sub use_mixin {
    my ( $self, $field, $mixin_s ) = @_;

    $mixin_s = ref($mixin_s) eq "ARRAY" ? $mixin_s : [$mixin_s];

    if ( ref($mixin_s) eq "ARRAY" ) {
        foreach my $mixin ( @{$mixin_s} ) {
            if ( defined $self->{mixins}->{$mixin} ) {
                $self->fields->{$field} =
                  $self->_merge_field_with_mixin( $self->fields->{$field},
                    $self->{mixins}->{$mixin} );
            }
        }
    }

    return 1;
}

sub use_mixin_field {
    my ( $self, $field, $target ) = @_;

    $self->check_field( $field, $self->fields->{$field} );

    # name and label overwrite restricted
    my $name = $self->fields->{$target}->{name}
      if defined $self->fields->{$target}->{name};
    my $label = $self->fields->{$target}->{label}
      if defined $self->fields->{$target}->{label};

    $self->fields->{$target} =
      $self->_merge_field_with_field( $self->fields->{$target}, $self->fields->{$field} );

    $self->fields->{$target}->{name}  = $name  if defined $name;
    $self->fields->{$target}->{label} = $label if defined $label;

    while ( my ( $key, $val ) = each( %{ $self->fields->{$field} } ) ) {
        if ( $key eq 'mixin' ) {
            $self->use_mixin( $target, $key );
        }
    }

    return 1;
}

=head2 validate

The validate method returns a hashref of defined validation templates.

    my $mixins = $self->mixins();
    ...

=cut

sub validate {
    my ( $self, @fields ) = @_;
    
    # first things first, reset the errors attribute in preparation for multiple
    # validation calls
    $self->reset_errors();
    
    # save unaltered state-of-parameters
    my %original_parameters = %{$self->params};

    # create alias map manually if requested
    if ( "HASH" eq ref $fields[0] ) {
        my $map = $fields[0];
        @fields = ();
        foreach my $param ( keys %{$map} ) {
            my $param_value = $self->params->{$param};
            delete $self->params->{$param};
            $self->params->{ $map->{$param} } = $param_value;
            push @fields, $map->{$param};
        }
    }
    
    # create map from aliases if applicable
    @fields = () unless scalar @fields;
    foreach my $field (keys %{$self->fields}) {
        my $f = $self->fields->{$field};
        if (defined $f->{alias}) {
            my $aliases = "ARRAY" eq ref $f->{alias} ?
                $f->{alias} : [$f->{alias}];
            
            foreach my $alias (@{$aliases}) {
                if (defined $self->params->{$alias}) {
                    my $param_value = $self->params->{$alias};
                    delete $self->params->{$alias};
                    $self->params->{ $field } = $param_value;
                    push @fields, $field;
                }
            }
        }
    }

    if ( $self->params ) {
        if ( !@fields ) {

            # process all params
            foreach my $field ( keys %{ $self->params } ) {
                if ( !defined $self->fields->{$field} ) {
                    my $death_cert
                        = "Data validation field $field does not exist";
                    $self->_suicide_by_unknown_field($death_cert);
                }
                my $this = $self->fields->{$field};
                $this->{name}  = $field;
                $this->{value} = $self->params->{$field};
                my @passed = ( $self, $this, $self->params );

                # execute simple validation
                $self->use_validator( $field, $this );

                # custom validation
                if ( defined $self->fields->{$field}->{validation} ) {
                    unless ( $self->fields->{$field}->{validation}->(@passed) )
                    {
                        if ( defined $self->fields->{$field}->{error} ) {
                            $self->error( $self->fields->{$field},
                                $self->fields->{$field}->{error} );
                        }
                    }
                }
            }
        }
        else {
            foreach my $field (@fields) {
                if ( !defined $self->fields->{$field} ) {
                    my $death_cert
                        = "Data validation field $field does not exist";
                    $self->_suicide_by_unknown_field($death_cert);
                }
                my $this = $self->fields->{$field};
                $this->{name}  = $field;
                $this->{value} = $self->params->{$field};
                my @passed = ( $self, $this, $self->params );

                # execute simple validation
                $self->use_validator( $field, $this );

                # custom validation
                if ( defined $self->fields->{$field}->{validation} ) {
                    unless ( $self->fields->{$field}->{validation}->(@passed) )
                    {
                        if ( defined $self->fields->{$field}->{error} ) {
                            $self->error( $self->fields->{$field},
                                $self->fields->{$field}->{error} );
                        }
                    }
                }
            }
        }
    }
    else {
        if (@fields) {
            foreach my $field (@fields) {
                if ( !defined $self->fields->{$field} ) {
                    my $death_cert
                        = "Data validation field $field does not exist";
                    $self->_suicide_by_unknown_field($death_cert);
                }
                my $this = $self->fields->{$field};
                $this->{name}  = $field;
                $this->{value} = $self->params->{$field};
                my @passed = ( $self, $this, $self->params );

                # execute simple validation
                $self->use_validator( $field, $this );

                # custom validation
                if ( $self->fields->{$field}->{value}
                    && defined $self->fields->{$field}->{validation} )
                {
                    unless ( $self->fields->{$field}->{validation}->(@passed) )
                    {
                        if ( defined $self->fields->{$field}->{error} ) {
                            $self->error( $self->fields->{$field},
                                $self->fields->{$field}->{error} );
                        }
                    }
                }
            }
        }

        # if no parameters are found, instead of dying, warn and continue
        elsif ( !$self->params || ref( $self->params ) ne "HASH" ) {

            # warn
            #     "No valid parameters were found, " .
            #     "parameters are required for validation";
            foreach my $field ( keys %{ $self->fields } ) {
                my $this = $self->fields->{$field};
                $this->{name}  = $field;
                $this->{value} = $self->params->{$field};

                # execute simple validation
                $self->use_validator( $field, $this );

                # custom validation shouldn't fire without params and data
                # my @passed = ($self, $this, {});
                # $self->fields->{$field}->{validation}->(@passed);
            }
        }

        #default - probably unneccessary
        else {
            foreach my $field ( keys %{ $self->fields } ) {
                my $this = $self->fields->{$field};
                $this->{name}  = $field;
                $this->{value} = $self->params->{$field};

                # execute simple validation
                $self->use_validator( $field, $this );

                # custom validation shouldn't fire without params and data
                # my @passed = ($self, $this, {});
                # $self->fields->{$field}->{validation}->(@passed);
            }
        }
    }

    $self->params({%original_parameters});

    return @{ $self->{errors} } ? 0 : 1;    # returns true if no errors
}

sub use_validator {
    my ( $self, $field, $this ) = @_;

    # does field have a label, if not use field name
    my $name = $this->{label} ? $this->{label} : "parameter $field";
    my $value = $this->{value};

    # check if required
    if ( $this->{required} && ( !defined $value || $value eq '' ) ) {
        my $error =
          defined $this->{error} ? $this->{error} : "$name is required";
        $self->error( $this, $error );
        return 1;    # if required and fails, stop processing immediately
    }

    if ( $this->{required} || $value ) {

        # find and process all the validators
        foreach my $key (keys %{$this}) {
            if ($self->directives->{$key}) {
                if ($self->directives->{$key}->{validator}) {
                    if ("CODE" eq ref $self->directives->{$key}->{validator}) {
                        
                        # validate
                        my $result = $self->directives->{$key}
                        ->{validator}->($this->{$key}, $value, $this, $self);
                        
                    }
                }
            }
        }

    }

    return 1;
}

sub use_filter {
    my ( $self, $filter, $field ) = @_;

    if ( defined $self->params->{$field} && $self->filters->{$filter} ) {
        $self->params->{$field} = $self->filters->{$filter}->( $self->params->{$field} )
            if $self->params->{$field};
    }

}

=head1 PARAMETER HANDLING

The following are convenience functions for handling your input data after
processing and data validation.

=cut

=head2 get_params

The get_params method returns the values (in list form) of the parameters
specified.

    if ($self->validate) {
        my $name = $self->get_params('name');
        my ($name, $email, $login, $password) =
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
    return map {
        $self->params->{$_}
    }   @params;
}

=head1 ERROR HANDLING

The most important part of any input validation framework is its ease-of-use and
its error handling. Validation::Class gives you the ability to bypass, override
and/or clear errors at-will without a hassle. The following methods assist you in
doing just that.

=cut

=head2 error_fields

The error_fields method returns a hashref of fields whose value is an arrayref
of error messages.

    unless ($self->validate) {
        my $fields = $self->error_fields();
    }

=cut

sub error_fields {
    my ($self) = @_;
    my $error_fields = {};

    for my $field ( keys %{ $self->fields } ) {
        my $errors = $self->fields->{$field}->{errors};
        if ( @{$errors} ) {
            $error_fields->{$field} = $errors;
        }
    }

    return $error_fields;
}

=head2 reset_errors

The reset_errors method clears all errors, both at the class and individual
field levels. This method is called automatically everytime the validate()
method is triggered.

    $self->reset_errors();

=cut

sub reset_errors {
    my $self = shift;
       $self->{errors} = [];
    
    for my $field ( keys %{ $self->fields } ) {
        $self->fields->{$field}->{errors} = [];
    }
}

=head2 error

The error function is used to set and/or retrieve errors encountered during
validation. The error function with no parameters returns the error message object
which is an arrayref of error messages stored at class-level. 

    # return all errors encountered/set as an arrayref
    return $self->error();
    
    # return all errors specific to the specified field (at the field-level)
    # as an arrayref
    return $self->error('some_param');
    
    # set an error specific to the specified field (at the field-level)
    # using the field object (hashref not field name)
    $self->error($field_object, "i am your error message");

    unless ($self->validate) {
        my $fields = $self->error();
    }

=cut

sub error {
    my ( $self, @params ) = @_;

    if ( @params == 2 ) {

        # set error message
        my ( $field, $error_msg ) = @params;
        if ( ref($field) eq "HASH" && ( !ref($error_msg) && $error_msg ) ) {
            if ( defined $self->fields->{ $field->{name} }->{error} ) {

                # temporary, may break stuff
                $error_msg = $self->fields->{ $field->{name} }->{error};

                push @{ $self->fields->{ $field->{name} }->{errors} },
                  $error_msg
                  unless grep { $_ eq $error_msg }
                      @{ $self->fields->{ $field->{name} }->{errors} };
                push @{ $self->{errors} }, $error_msg
                  unless grep { $_ eq $error_msg } @{ $self->{errors} };
            }
            else {
                push @{ $self->fields->{ $field->{name} }->{errors} },
                  $error_msg
                  unless grep { $_ eq $error_msg }
                      @{ $self->fields->{ $field->{name} }->{errors} };
                push @{ $self->{errors} }, $error_msg
                  unless grep { $_ eq $error_msg } @{ $self->{errors} };
            }
        }
        else {
            die "Can't set error without proper field and error message data, "
              . "field must be a hashref with name and value keys";
        }
    }
    elsif ( @params == 1 ) {

        # return param-specific errors
        return $self->fields->{ $params[0] }->{errors};
    }
    else {

        # return all errors
        return $self->{errors};
    }

    return 0;
}

=head2 errors

The errors function returns a special class (Validation::Class::Errors) used to
add convenience methods to the error objects. This class can be utilized as
follows. 

    # by default uses errors specified at the class-level
    return $self->errors;
    
    # count() method returns the number of errors encoutered
    return $self->errors->count();
    
    # to_string($delimiter) method strigifies the error arrayref object using
    # the specified delimiter or ', ' by default
    return $self->errors->to_string();
    return $self->errors->to_string("<br/>\n");
    
    # use errors at the field-level in the errors class
    return $self->errors($self->fields->{some_field})->count();

    unless ($self->validate) {
        return $self->errors->to_string;
    }

=cut

sub errors {
    my ($self, $errobj) = @_;
    Validation::Class::Errors->new(errors => $errobj || $self->{errors} || []);
}

sub _suicide_by_unknown_field {
    my $self  = shift;
    my $error = shift;
    if ($self->ignore_unknown) {
        if ($self->report_unknown) {
            push @{ $self->{errors} }, $error
                unless grep { $_ eq $error } @{ $self->{errors} };
        }
    }
    else {
        die $error ;
    }
}

sub _merge_field_with_mixin {
    my ($self, $field, $mixin) = @_;
    while (my($key,$value) = each(%{$mixin})) {
        if (defined $self->types->{field}->{$key}) {
            $field->{$key} = $value;
        }
    }
    return $field;
}

sub _merge_field_with_field {
    my ($self, $field, $mixin_field) = @_;
    while (my($key,$value) = each(%{$mixin_field})) {
        
        # skip unless the directive is mixin compatible
        next unless $self->types->{mixin}->{$key}->{mixin};
        
        if (defined $self->types->{field}->{$key}) {
            $field->{$key} = $value;
        }
    }
    return $field;
}

    package
        Validation::Class::Errors;
    
    # Error Class for Validation::Class
    
    use Moose;
    
    has 'errors' => (
        is      => 'rw',
        isa     => 'ArrayRef',
        default => sub { [] }
    );
    
    sub count {
        return scalar(@{shift->errors});
    }
    
    sub to_string {
        return join(($_[1]||', '), @{$_[0]->errors});
    }
    
    # End of Validation::Class::Errors


1;    # End of Validation::Class
