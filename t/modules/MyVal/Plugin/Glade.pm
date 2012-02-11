package MyVal::Plugin::Glade;

use Moose::Role;

has smell => (
    is      => 'rw',
    isa     => 'Str',
    default => 'Good'
);

sub squirt {
    1
}

1;
