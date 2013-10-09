package Sample::Server::Web::Controller::OAuth;
use Mojo::Base 'Mojolicious::Controller';
use Sample::Server::Model;
use Sample::Server::Model::DataHandler;
use OAuth::Lite2::Server::GrantHandler::Password;
use OAuth::Lite2::Server::GrantHandler::RefreshToken;
use Plack::Request;

sub token {
    my $self = shift;
    my $grant_type = $self->req->param('grant_type');
    my $plack_request = Plack::Request->new( $self->req->env() );
    my $data;
    if($grant_type eq 'refresh_token') {
        $data = $self->handle_refresh_token($plack_request);
    }elsif($grant_type eq 'password'){
        $data = $self->handle_password($plack_request);
    }
    $self->render( json => $data );
}

sub handle_password {
    my ($self, $request) = @_;
    my $password_handler = OAuth::Lite2::Server::GrantHandler::Password->new;
    my $data_handler = Sample::Server::Model::DataHandler->new( request => $request );
    my $data = $password_handler->handle_request($data_handler);
    return $data;
}

sub handle_refresh_token {
    my ($self, $request) = @_;
    my $refresh_handler = OAuth::Lite2::Server::GrantHandler::RefreshToken->new;
    my $data_handler = Sample::Server::Model::DataHandler->new( request => $request );
    my $auth_info = $data_handler->create_or_update_auth_info(
        client_id => $request->param('client_id') || undef,
        client_secret => $request->param('client_secret') || undef,
        refresh_token => $request->param('refresh_token') || undef,
    );
    my $data = $refresh_handler->handle_request( $data_handler );
    return $data;
}

1;
