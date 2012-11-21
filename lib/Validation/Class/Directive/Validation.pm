# ABSTRACT: Validation Directive for Validation Class Field Definitions

package Validation::Class::Directive::Validation;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::Validation;

    my $directive = Validation::Class::Directive::Validation->new;

=head1 DESCRIPTION

Validation::Class::Directive::Validation is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin'        => 0;
has 'field'        => 1;
has 'multi'        => 0;
has 'message'      => '%s could not be validated';
# ensure most core directives execute before this one
has 'dependencies' => sub {{
    normalization => [],
    validation    => [qw(
        alias
        between
        default
        depends_on
        error
        errors
        filtering
        filters
        label
        length
        matches
        max_alpha
        max_digits
        max_length
        max_sum
        min_alpha
        min_digits
        min_length
        min_sum
        mixin
        mixin_field
        multiples
        name
        options
        pattern
        readonly
        required
        toggle
        value
    )]
}};

sub validate {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    if (defined $field->{validation} && defined $param) {

        my $context = $proto->stash->{'validation.context'};

        my $count  = ($proto->errors->count+$field->errors->count);
        my $failed = !$field->validation->($context,$field,$proto->params)?1:0;
        my $errors = ($proto->errors->count+$field->errors->count)>$count ?1:0;

        # error handling; did the validation routine pass or fail?

        # validation passed with no errors
        if (!$failed && !$errors) {
            # noop
        }

        # validation failed with no errors
        elsif ($failed && !$errors) {
            $self->error(@_);
        }

        # validation passed with errors
        elsif (!$failed && $errors) {
            # noop -- but acknowledge errors have been set
        }

        # validation failed with errors
        elsif ($failed && $errors) {
            # assume errors have been set from inside the validation routine
        }

    }

    return $self;

}

1;
