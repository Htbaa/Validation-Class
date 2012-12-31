# ABSTRACT: Filters Directive for Validation Class Field Definitions

package Validation::Class::Directive::Filters;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

# VERSION

our $_registry = {

    alpha        => \&filter_alpha,
    alphanumeric => \&filter_alphanumeric,
    capitalize   => \&filter_capitalize,
    decimal      => \&filter_decimal,
    lowercase    => \&filter_lowercase,
    numeric      => \&filter_numeric,
    strip        => \&filter_strip,
    titlecase    => \&filter_titlecase,
    trim         => \&filter_trim,
    uppercase    => \&filter_uppercase

};

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            user_ident => {
                filters => 'trim'
            }
        }
    );

    # set parameters to be validated
    $rules->params->add($parameters);

    # validate
    unless ($rules->validate) {
        # handle the failures
    }

=head1 DESCRIPTION

Validation::Class::Directive::Filters is a core validation class field directive
that specifies which filter should be executed on the associated field.

=over 8

=item * alternative argument: an-array-of-options

=item * option: trim e.g. remove leading/trailing spaces

=item * option: strip e.g. replace multiple spaces with one space

=item * option: lowercase e.g. convert to lowercase

=item * option: uppercase e.g. convert to uppercase

=item * option: titlecase e.g. uppercase first letter of each word

=item * option: capitalize e.g. uppercase the first letter

=item * option: alphanumeric e.g. remove non-any alphanumeric characters

=item * option: numeric e.g. remove any non-numeric characters

=item * option: alpha e.g. remove any non-alpha characters

=item * option: decimal e.g. preserve only numeric, dot and comma characters

This directive can be passed a single value or an array of values:

    fields => {
        user_ident => {
            filters => ['trim', 'strip']
        }
    }

=back

=cut

sub registry {

    return $_registry;

}

sub filter_alpha {

    $_[0] =~ s/[^A-Za-z]//g;
    return $_[0];

}

sub filter_alphanumeric {

    $_[0] =~ s/[^A-Za-z0-9]//g;
    return $_[0];

}

sub filter_capitalize {

    $_[0] = ucfirst $_[0];
    $_[0] =~ s/\.\s+([a-z])/\. \U$1/g;
    return $_[0];

}

sub filter_decimal {

    $_[0] =~ s/[^0-9\.\,]//g;
    return $_[0];

}

sub filter_lowercase {

    return lc $_[0];

}

sub filter_numeric {

    $_[0] =~ s/\D//g;
    return $_[0];

}

sub filter_strip {

    $_[0] =~ s/\s+/ /g;
    $_[0] =~ s/^\s+//;
    $_[0] =~ s/\s+$//;
    return $_[0];

}

sub filter_titlecase {

    return join( " ", map { ucfirst $_ } (split( /\s/, lc $_[0] )) );

}

sub filter_trim {

    $_[0] =~ s/^\s+//g;
    $_[0] =~ s/\s+$//g;
    return $_[0];

}

sub filter_uppercase {

    return uc $_[0];

}

has 'mixin' => 1;
has 'field' => 1;
has 'multi' => 1;
has 'dependencies' => sub {{
    normalization => ['filtering'],
    validation    => []
}};

sub after_validation {

    my ($self, $proto, $field, $param) = @_;

    if ($proto->validated == 2) {
        $self->execute_filtering($proto, $field, $param, 'post');
    }

    return $self;

}

sub before_validation {

    my ($self, $proto, $field, $param) = @_;

    $self->execute_filtering($proto, $field, $param, 'pre');

    return $self;

}

sub normalize {

    my ($self, $proto, $field, $param) = @_;

    # by default fields should have a filters directive
    # unless already specified

    if (! defined $field->{filters}) {

        $field->{filters} = [];

    }

    # run any existing filters on instantiation
    # if the field is set to pre-filter

    else {

        $self->execute_filtering($proto, $field, $param, 'pre');

    }

    return $self;

}

sub execute_filtering {

    my ($self, $proto, $field, $param, $state) = @_;

    return unless $state;

    if (defined $field->{filters} && defined $field->{filtering} && defined $param) {

            if ($field->{filtering} eq $state && $state ne 'off') {

            my @filters = isa_arrayref($field->{filters}) ?
                    @{$field->{filters}} : ($field->{filters});

            my $values = $param;

            foreach my $value (isa_arrayref($param) ? @{$param} : ($param)) {

                next if ! $value;

                foreach my $filter (@filters) {

                    $filter = $proto->filters->get($filter)
                        unless isa_coderef($filter);

                    next if ! $filter;

                    $value  = $filter->($value);

                }

            }

            my $name = $field->name;

            $proto->params->add($name, $param);

        }

    }

    return $self;

}

1;
