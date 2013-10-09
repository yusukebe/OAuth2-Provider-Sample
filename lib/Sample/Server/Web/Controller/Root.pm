package Sample::Server::Web::Controller::Root;
use Mojo::Base 'Mojolicious::Controller';

sub index {
    my $self = shift;
    $self->render('index');
}

sub protected_resource {
    my $self = shift;
    my $user = $self->stash->{user};
    return $self->render_not_found_x unless $user;
    $self->render(json => { data => $user });
}

1;
