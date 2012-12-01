# ABSTRACT: State Directive for Validation Class Field Definitions

package Validation::Class::Directive::State;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

# VERSION

=head1 DESCRIPTION

Validation::Class::Directive::State is a core validation class
field directive that provides the ability to do some really cool stuff only we
haven't documented it just yet.

=cut

has 'mixin'   => 1;
has 'field'   => 1;
has 'multi'   => 0;
has 'message' => '%s is not a valid state';
has 'regexp'  => sub {sprintf'^(%s)$',join'|',map{quotemeta}@{shift->states}};
has 'states'  => sub {[ # u.s. states and territories
    'Alabama',
    'Alaska',
    'Arizona',
    'Arkansas',
    'California',
    'Colorado',
    'Connecticut',
    'Delaware',
    'Florida',
    'Georgia',
    'Hawaii',
    'Idaho',
    'Illinois',
    'Indiana',
    'Iowa',
    'Kansas',
    'Kentucky',
    'Louisiana',
    'Maine',
    'Maryland',
    'Massachusetts',
    'Michigan',
    'Minnesota',
    'Mississippi',
    'Missouri',
    'Montana',
    'Nebraska',
    'Nevada',
    'New Hampshire',
    'New Jersey',
    'New Mexico',
    'New York',
    'North Carolina',
    'North Dakota',
    'Ohio',
    'Oklahoma',
    'Oregon',
    'Pennsylvania',
    'Rhode Island',
    'South Carolina',
    'South Dakota',
    'Tennessee',
    'Texas',
    'Utah',
    'Vermont',
    'Virginia',
    'Washington',
    'West Virginia',
    'Wisconsin',
    'Wyoming',
    'District of Columbia',
    'Puerto Rico',
    'Guam',
    'American Samoa',
    'U.S. Virgin Islands',
    'Northern Mariana Islands',
]};

sub validate {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{state}) {

        if (defined $param) {

            my $type = $field->{state};
            my $lre  = $self->regexp;

            my $sre = {
                'abbr' => qr/^(A[LKSZRAEP]|C[AOT]|D[EC]|F[LM]|G[AU]|HI|I[ADLN]|K[SY]|LA|M[ADEHINOPST]|N[CDEHJMVY]|O[HKR]|P[ARW]|RI|S[CD]|T[NX]|UT|V[AIT]|W[AIVY])$/i,
                'long' => qr/$lre/i,
            };

            my $is_valid = 0;

            $type = isa_arrayref($type) ? $type : $type == 1 ? [keys %$sre] : [$type];

            for (@{$type}) {

                if ($param =~ $sre->{$_}) {
                    $is_valid = 1;
                    last;
                }

            }

            $self->error($proto, $field) unless $is_valid;

        }

    }

    return $self;

}

1;
