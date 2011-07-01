package Validation::Class;

# ABSTRACT: Centralized Input Validation For Any Application

use strict;
use warnings;
use 5.008001;
use Moose;
use Moose::Exporter;
use Array::Unique;
use Hash::Merge;

    Moose::Exporter->setup_import_methods(
        as_is  => [ 'field', 'filter', 'mixin' ],
        also   => 'Moose',
    );

our $FIELDS  = {};
our $MIXINS  = {};
our $FILTERS = {};



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


sub mixin {
    my %spec = @_;

    if (%spec) {
        my $name = ( keys(%spec) )[0];
        my $data = ( values(%spec) )[0];

        $MIXINS->{$name} = $data;
    }

    return 'mixin', %spec;
}


sub filter {
    my %spec = @_;

    if (%spec) {
        my $name = ( keys(%spec) )[0];
        my $data = ( values(%spec) )[0];

        $FILTERS->{$name} = $data;
    }

    return 'filter', %spec;
}



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
                    $self->basic_filter( $filter, $_ );
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

    return $self;
};


# validation rules store
has 'fields' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { $FIELDS }
);


# mixin/field types store
has 'filters' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        {
            trim => sub {
                $_[0] =~ s/^\s+//g;
                $_[0] =~ s/\s+$//g;
            },
            alpha => sub {
                $_[0] =~ s/[^A-Za-z]//g;
            },
            digit => sub {
                $_[0] =~ s/\D//g;
            },
            whiteout => sub {
                $_[0] =~ s/\s+/ /g;
            },
            numeric => sub {
                $_[0] =~ s/[^0-9]//g;
            },
            uppercase => sub {
                return uc $_[0];
            },
            titlecase => sub {
                map ( ucfirst, split( /\s/, $_[0] ) );
            },
            camelcase => sub {
                map ( ucfirst, split( /\s/, lc $_[0] ) );
            },
            lowercase => sub {
                return lc $_[0];
            },
            alphanumeric => sub {
                $_[0] =~ s/[^A-Za-z0-9]//g;
              }
        };
      }
);


# ignore unknown input parameters
has 'ignore_unknown' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0
);


# report unknown input parameters
has 'report_unknown' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0
);


# input parameters store
has 'params' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} }
);


# validation rules templates store
has 'mixins' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { $MIXINS }
);

# mixin/field types store
has 'types' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        {
            field => {
                mixin       => sub { 1 },
                mixin_field => sub { 1 },
                validation  => sub { 1 },
                errors      => sub { 1 },
                label       => sub { 1 },
                error       => sub { 1 },
                value       => sub { 1 },
                name        => sub { 1 },
                filter      => sub { 1 },
                filters     => sub { 1 },
                required    => sub { 1 },
                min_length  => sub { 1 },
                max_length  => sub { 1 },
                data_type   => sub { 1 },
                ref_type    => sub { 1 },
                regex       => sub { 1 }
            },
            mixin => {
                required   => sub { 1 },
                min_length => sub { 1 },
                max_length => sub { 1 },
                data_type  => sub { 1 },
                ref_type   => sub { 1 },
                regex      => sub { 1 },
                filter     => sub { 1 },
                filters    => sub { 1 },
                validation => sub { 1 }
            }
        };
      }
);

sub check_mixin {
    my ( $self, $mixin, $spec ) = @_;

    my $directives = $self->types->{mixin};

    foreach ( keys %{$spec} ) {
        if ( !defined $directives->{$_} ) {
            die
              "The $_ directive supplied by the $mixin mixin is not supported";
        }
        if ( !$directives->{$_} ) {
            die "The $_ directive supplied by the $mixin mixin is invalid";
        }
    }

    return 1;
}

sub check_field {
    my ( $self, $field, $spec ) = @_;

    my $directives = $self->types->{field};

    foreach ( keys %{$spec} ) {
        if ( !defined $directives->{$_} ) {
            die
              "The $_ directive supplied by the $field field is not supported";
        }
        if ( !$directives->{$_}->() ) {
            die "The $_ directive supplied by the $field field is invalid";
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
                  Hash::Merge::merge( $self->fields->{$field},
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
      Hash::Merge::merge( $self->fields->{$field}, $self->fields->{$target} );

    $self->fields->{$target}->{name}  = $name  if defined $name;
    $self->fields->{$target}->{label} = $label if defined $label;

    while ( my ( $key, $val ) = each( %{ $self->fields->{$field} } ) ) {
        if ( $key eq 'mixin' ) {
            $self->use_mixin( $target, $key );
        }
    }

    return 1;
}


sub validate {
    my ( $self, @fields ) = @_;
    
    # first things first, reset the errors attribute in preparation for multiple
    # validation calls
    $self->reset_errors();
    
    # translation (mainly for param => group:field operation)
    my %original_parameters = %{$self->params};

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
                $self->basic_validate( $field, $this );

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
                $self->basic_validate( $field, $this );

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
                $self->basic_validate( $field, $this );

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
                $self->basic_validate( $field, $this );

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
                $self->basic_validate( $field, $this );

                # custom validation shouldn't fire without params and data
                # my @passed = ($self, $this, {});
                # $self->fields->{$field}->{validation}->(@passed);
            }
        }
    }

    $self->params({%original_parameters});

    return @{ $self->{errors} } ? 0 : 1;    # returns true if no errors
}

sub basic_validate {
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

        if ( defined $this->{min_length} ) {
            if ( $this->{min_length} ) {
                if ( length($value) < $this->{min_length} ) {
                    my $error =
                      defined $this->{error} ? $this->{error}
                      : "$name must contain at least " 
                      . $this->{min_length}
                      . (
                        int( $this->{min_length} ) > 1 ? " characters"
                        : " character"
                      );
                    $self->error( $this, $error );
                }
            }
        }

        # check max character length
        if ( defined $this->{max_length} ) {
            if ( $this->{max_length} ) {
                if ( length($value) > $this->{max_length} ) {
                    my $error =
                      defined $this->{error} ? $this->{error}
                      : "$name cannot be greater than " 
                      . $this->{max_length}
                      . (
                        int( $this->{max_length} ) > 1 ? " characters"
                        : " character"
                      );
                    $self->error( $this, $error );
                }
            }
        }

        # check against regex
        if ( defined $this->{regex} ) {
            if ( $this->{regex} ) {
                unless ( $value =~ $this->{regex} ) {
                    my $error =
                      defined $this->{error}
                      ? $this->{error}
                      : "$name failed regular expression testing "
                      . "using $value";
                    $self->error( $this, $error );
                }
            }
        }

    }

    return 1;
}

sub basic_filter {
    my ( $self, $filter, $field ) = @_;

    if ( defined $self->params->{$field} && $self->filters->{$filter} ) {
        $self->filters->{$filter}->( $self->params->{$field} )
            if $self->params->{$field};
    }

}



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


sub reset_errors {
    my $self = shift;
       $self->{errors} = [];
    
    for my $field ( keys %{ $self->fields } ) {
        $self->fields->{$field}->{errors} = [];
    }
}


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

__END__
=pod

=head1 NAME

Validation::Class - Centralized Input Validation For Any Application

=head1 VERSION

version 0.111720

=head1 SYNOPSIS

    use MyApp::Validation;
    
    my $input = MyApp::Validation->new(params => $params);
    
    unless ($input->validate('field1', 'field2')){
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

=head3 ref_type

Determines whether the field value is a valid perl reference variable

=head3 regex

Determines whether the field value passes the supplied regular expression e.g.

    field 'c_field' => {
        label => 'a field labeled c',
        error => 'a field labeled c cannot be ...',
        required => 1,
        min_length => 2,
        max_length => 25,
        ref_type => 'array',
        regex => '^\d+$'
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

=head2 MIXIN KEYWORD

The mixin keyword creates a validation rules template that can be applied to any
field using the mixin directive.

    package MyApp::Validation;
    use Validation::Class qw/field mixin filter/;
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

=head2 FILTER KEYWORD

The filter keyword creates custom filters to be used in your field definitions.

    package MyApp::Validation;
    use Validation::Class qw/field mixin filter/;
    10use base 'Validation::Class';
    
    filter 'telephone' => sub {
        $_[0] =~ s/[^\(\)\-\+\s\d]//g;
    };
    
    field 'telephone' => {
        filter => ['trim', 'telephone'],
        ...
    };

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
names using the same group naming convention. if this is not to your liking,
the validate() method can assist you in mapping your incoming parameters to your
defined validation fields as shown here:

    use MyApp::Validation;
    
    my $input = MyApp::Validation->new(params => $params);
    unless ($input->validate({ user => 'user:login', pass => 'user:password')){
        return $input->errors->to_string;
    }

=head2 new

The new method instantiates and returns an instance of your validation class.

    use MyApp::Validation;
    
    my $input = MyApp::Validation->new;
    $input->params($params);
    ...

or

    my $input = MyApp::Validation->new(params => $params);
    ...

=head2 fields

The fields attribute returns a hashref of defined fields, filtered and merged with
thier parameter counterparts.

    my $fields = $self->fields();
    ...

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

=head2 ignore_unknown

The ignore_unknown boolean determines whether your application will live or die
upon encountering unregistered fields during validation.

    MyApp::Validation->new(params => $params, ignore_unknown => 1);
    
    or
    
    $self->ignore_unknown(1);
    ...

=head2 report_unknown

The report_unknown boolean determines whether your application will report
unregistered fields as class-level errors upon encountering unregistered fields
during validation.

    MyApp::Validation->new(params => $params,
    ignore_unknown => 1, report_unknown => 1);
    
    or
    
    $self->report_unknown(1);
    ...

=head2 params

The params attribute gets/sets the parameters to be validated.

    my $input = {
        ...
    };
    
    $self->params($input);
    my $params = $self->params();
    
    ...

=head2 mixins

The mixins attribute returns a hashref of defined validation templates.

    my $mixins = $self->mixins();
    ...

=head2 validate

The validate method returns a hashref of defined validation templates.

    my $mixins = $self->mixins();
    ...

=head1 ERROR HANDLING

The most important part of any input validation framework is its ease-of-use and
its error handling. Validation::Class gives you the ability to bypass, override
and/or clear errors at-will without a hassle. The following methods assist you in
doing just that.

=head2 error_fields

The error_fields method returns a hashref of fields whose value is an arrayref
of error messages.

    unless ($self->validate) {
        my $fields = $self->error_fields();
    }

=head2 reset_errors

The reset_errors method clears all errors, both at the class and individual
field levels. This method is called automatically everytime the validate()
method is triggered.

    $self->reset_errors();

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

=head1 AUTHOR

Al Newkirk <awncorp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

