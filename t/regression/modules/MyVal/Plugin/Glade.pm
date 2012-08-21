package MyVal::Plugin::Glade;

sub new {

    my ($plugin, $caller) = @_;

    $caller->stash(smell  => \&smell);
    $caller->stash(squirt => \&squirt);

    $caller->set_method(squash => sub {'abc'});

    return bless {}, $plugin;

}

sub smell  {'Good'}
sub squirt {1}

1;
