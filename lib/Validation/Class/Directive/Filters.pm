# ABSTRACT: Filters Directive for Validation Class Field Definitions

package Validation::Class::Directive::Filters;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::Filters;

    my $directive = Validation::Class::Directive::Filters->new;

=head1 DESCRIPTION

Validation::Class::Directive::Filters is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

sub defaults {{

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

}}

sub filter_alpha {

    $_[0] =~ s/[^A-Za-z]//g;
    $_[0];

}

sub filter_alphanumeric {

    $_[0] =~ s/[^A-Za-z0-9]//g;
    $_[0];

}

sub filter_capitalize {

    $_[0] = ucfirst $_[0];
    $_[0] =~ s/\.\s+([a-z])/\. \U$1/g;
    $_[0];

}

sub filter_decimal {

    $_[0] =~ s/[^0-9\.\,]//g;
    $_[0];

}

sub filter_lowercase {

    lc $_[0];

}

sub filter_numeric {

    $_[0] =~ s/\D//g;
    $_[0];

}

sub filter_strip {

    $_[0] =~ s/\s+/ /g;
    $_[0] =~ s/^\s+//;
    $_[0] =~ s/\s+$//;
    $_[0];

}

sub filter_titlecase {

    join( " ", map ( ucfirst, split( /\s/, lc $_[0] ) ) );

}

sub filter_trim {

    $_[0] =~ s/^\s+//g;
    $_[0] =~ s/\s+$//g;
    $_[0];

}

sub filter_uppercase {

    uc $_[0];

}

has 'mixin' => 1;
has 'field' => 1;
has 'multi' => 1;

sub after_validation {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{filters} && defined $field->{filtering}) {

            if ($field->{filtering} eq 'post') {

            my @filters = map { $proto->filters->get($_) }
                isa_arrayref($field->{filters}) ?
                    @{$field->{filters}} : ($field->{filters})
            ;

            my @values = isa_arrayref($param) ?
                @{$param} : ($param)
            ;

            foreach my $value (@values) {
                next if ! $value;
                $value = $_->($value) for @filters;
            }

        }

    }

    return $self;

}

sub before_validation {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{filters} && defined $field->{filtering}) {

            if ($field->{filtering} eq 'pre') {

            my @filters = map { $proto->filters->get($_) }
                isa_arrayref($field->{filters}) ?
                    @{$field->{filters}} : ($field->{filters})
            ;

            my @values = isa_arrayref($param) ?
                @{$param} : ($param)
            ;

            foreach my $value (@values) {
                next if ! $value;
                $value = $_->($value) for @filters;
            }

        }

    }

    return $self;

}

sub normalize {

    my ($self, $proto, $field, $param) = @_;

    # by default fields should have a filters directive
    # unless already specified

    if (! defined $field->{filters}) {

        $field->{filters} = [];

    }

    return $self;

}

1;
