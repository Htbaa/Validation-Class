# ABSTRACT: Simple Inline Validation Class

package Validation::Class::Simple;

use Validation::Class;

# VERSION

=head2 SYNOPSIS

    use Validation::Class::Simple;
    
    my $fields = {
        'login'  => {
            label      => 'User Login',
            error      => 'Login invalid.',
            required   => 1,
            validation => sub {
                my ($self, $this_field, $all_params) = @_;
                return $this_field->{value} eq 'admin' ? 1 : 0;
            }
        },
        'password'  => {
            label         => 'User Password',
            error         => 'Password invalid.',
            required      => 1,
            validation    => sub {
                my ($self, $this_field, $all_params) = @_;
                return $this_field->{value} eq 'pass' ? 1 : 0;
            }
        }    
    };
    
    my $input = Validation::Class::Simple->new(    
        fields => $fields, params => $params
    );
    
    unless ( $input->validate ) {
        return $input->errors_to_string;
    }

=cut

=head1 DESCRIPTION

Validation::Class::Simple is a drop-in validation class derived from the
L<Validation::Class> framework. This package is intended to be used in
situations where a full-fledged validation class is not warranted,
e.g. (scripts, etc).

Simply define your data validation profile and execute, much in the same way
you would use most other data validation libraries available.

Should you find yourself wanting to switch to a full-fledged validation class
using L<Validation::Class>, you could do so very easily as the validation field
specification is exactly the same.

=cut

1;