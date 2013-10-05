package Sample::Server::Web::Controller::OAuth;
use Mojo::Base 'Mojolicious::Controller';
use Sample::Server::Model::DataHandler;
use OAuth::Lite2::Server::GrantHandler::Password;
use Plack::Request;

sub index {
    my $self = shift;
    $self->render( message => 'Welcome to the Mojolicious real-time web framework!');
}

sub token {
    my $self = shift;
    my $plack_request = Plack::Request->new( $self->req->env() );
    my $grant_type = $self->req->param('grant_type');
    my $data;
    $data = $self->handle_password($plack_request) if $grant_type eq 'password';
    $self->render( json => $data );
}

sub handle_password {
    my ($self, $request) = @_;
    my $password_handler = OAuth::Lite2::Server::GrantHandler::Password->new;
    my $data_handler = Sample::Server::Model::DataHandler->new( request => $request );
    my $data = $password_handler->handle_request($data_handler);
    return $data;
}

1;
