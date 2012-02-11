package MyVal::Plugin::Glade;

sub new {
    my $self = pop;
    $self->stash(smell => \&smell);
    $self->stash(squirt => \&squirt);
}

sub smell { 'Good' }
sub squirt { 1 }

1;
