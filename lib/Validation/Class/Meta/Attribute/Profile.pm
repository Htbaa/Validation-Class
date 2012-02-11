# Base Configuration Profile for a Validation::Class Instance

use strict;
use warnings;

package # Don't register with PAUSE (pause.perl.org)
    Validation::Class::Meta::Attribute::Profile
;

# VERSION

use Moose::Role;

has profile => (
    is  => 'rw',
    isa => 'HashRef',
    default => sub {{
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
                    my ($min, $max) = split /\-/, $directive;
                    
                    $min = scalar($min);
                    $max = scalar($max);
                    $value = length($value);
                    
                    if ($value) {
                        unless ($value >= $min && $value <= $max) {
                            my $handle = $field->{label} || $field->{name};
                            $class->error(
                                $field,
                                "$handle must contain between $directive characters"
                            );
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
                        my (@options) = split /\,\s?/, $directive;
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
    }}
);

1;