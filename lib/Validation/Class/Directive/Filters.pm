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

has 'mixin' => 1;
has 'field' => 1;
has 'multi' => 1;

sub normalize {

    my ($self, $proto, $field) = @_;

    # by default fields should have a filters directive
    # unless already specified

    if (! defined $field->{filters}) {

        $field->{filters} = [];

    }

    return $self;

}

sub filter_directive_alpha {

    $_[0] =~ s/[^A-Za-z]//g;
    $_[0];

}

sub filter_directive_alphanumeric {

    $_[0] =~ s/[^A-Za-z0-9]//g;
    $_[0];

}

sub filter_directive_capitalize {

    $_[0] = ucfirst $_[0];
    $_[0] =~ s/\.\s+([a-z])/\. \U$1/g;
    $_[0];

}

sub filter_directive_decimal {

    $_[0] =~ s/[^0-9\.\,]//g;
    $_[0];

}

sub filter_directive_lowercase {

    lc $_[0];

}

sub filter_directive_numeric {

    $_[0] =~ s/\D//g;
    $_[0];

}

sub filter_directive_strip {

    $_[0] =~ s/\s+/ /g;
    $_[0] =~ s/^\s+//;
    $_[0] =~ s/\s+$//;
    $_[0];

}

sub filter_directive_titlecase {

    join( " ", map ( ucfirst, split( /\s/, lc $_[0] ) ) );

}

sub filter_directive_trim {

    $_[0] =~ s/^\s+//g;
    $_[0] =~ s/\s+$//g;
    $_[0];

}

sub filter_directive_uppercase {

    uc $_[0];

}

1;
