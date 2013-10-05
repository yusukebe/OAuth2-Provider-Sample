package Sample::Server::Web;
use Mojo::Base 'Mojolicious';
use Plack::Request;
use Plack::Util::Accessor qw(realm data_handler error_uri);
use Try::Tiny;
use Carp ();
use OAuth::Lite2::Server::Error;
use OAuth::Lite2::ParamMethods;
use Sample::Server::Model::DataHandler;
use Sample::Server::Model;

sub startup {
    my $self = shift;

    $self->hook(
        before_dispatch => sub {
            my $c = shift;
            my $req = Plack::Request->new( $c->req->env );
            my $is_legacy = 0;
            my $error_res = try {
                my $parser = OAuth::Lite2::ParamMethods->get_param_parser($req)
                  or OAuth::Lite2::Server::Error::InvalidRequest->throw;
                $is_legacy = $parser->is_legacy($req);
                my ( $token, $params ) = $parser->parse($req);
                OAuth::Lite2::Server::Error::InvalidRequest->throw
                  unless $token;
                my $dh = Sample::Server::Model::DataHandler->new( request => $req );
                my $access_token = $dh->get_access_token($token);

                OAuth::Lite2::Server::Error::InvalidToken->throw
                  unless $access_token;

                Carp::croak
                        "OAuth::Lite2::Server::DataHandler::get_access_token doesn't return OAuth::Lite2::Model::AccessToken"
                  unless $access_token->isa("OAuth::Lite2::Model::AccessToken");

                unless ( $access_token->created_on + $access_token->expires_in >
                    time() )
                {
                    if ($is_legacy) {
                        OAuth::Lite2::Server::Error::ExpiredTokenLegacy->throw;
                    }
                    else {
                        OAuth::Lite2::Server::Error::ExpiredToken->throw;
                    }
                }

                my $auth_info =
                  $dh->get_auth_info_by_id( $access_token->auth_id );

                OAuth::Lite2::Server::Error::InvalidToken->throw
                  unless $auth_info;

                Carp::croak
"OAuth::Lite2::Server::DataHandler::get_auth_info_by_id doesn't return OAuth::Lite2::Model::AuthInfo"
                  unless $auth_info->isa("OAuth::Lite2::Model::AuthInfo");

                $dh->validate_client_by_id( $auth_info->client_id )
                  or OAuth::Lite2::Server::Error::InvalidToken->throw;

                $dh->validate_user_by_id( $auth_info->user_id )
                  or OAuth::Lite2::Server::Error::InvalidToken->throw;

                $c->stash->{REMOTE_USER} = $auth_info->user_id;
                $c->stash->{X_OAUTH_CLIENT} = $auth_info->client_id;
                $c->stash->{X_OAUTH_SCOPE} = $auth_info->scope if $auth_info->scope;
                $c->stash->{X_OAUTH_IS_LEGACY} = ($is_legacy);

                #XXX
                my $user = Sample::Server::Model->new->db->single('user', { id => $auth_info->user_id });
                $c->stash->{user} = $user->get_columns();
                return;
            }
            catch {
                if ( $_->isa("OAuth::Lite2::Server::Error") ) {
                    my @params;
                    push( @params, sprintf( q{realm="%s"}, $self->{realm} ) ) if $self->{realm};
                    push( @params, sprintf( q{error="%s"}, $_->type ) );
                    push( @params, sprintf( q{error_description="%s"}, $_->description ) ) if $_->description;
                    push( @params, sprintf( q{error_uri="%s"}, $self->{error_uri} ) ) if $self->{error_uri};
                    if ($is_legacy) { 
                        return [
                            $_->code,
                            [
                                "WWW-Authenticate" => "OAuth "
                                  . join( ', ', @params )
                            ],
                            []
                        ];
                    }
                    else {
                        return [
                            $_->code,
                            [
                                "WWW-Authenticate" => "Bearer "
                                  . join( ', ', @params )
                            ],
                            []
                        ];
                    }
                }
                else {
                    die $_;
                }
            }
        }
    );


    my $r = $self->routes;
    $r->namespaces([qw/Sample::Server::Web::Controller/]);

    $r->route('/')->to( controller => 'Root', action => 'index' );

    $r->get('/admin')->to( controller => 'Admin', action => 'index' );
    $r->post('/admin/add_user')->to( controller => 'Admin', action => 'add_user' );
    $r->post('/admin/add_client')->to( controller => 'Admin', action => 'add_client' );

    $r->get('/oauth/authorize')->to( controller => 'OAuth', action => 'authorize' );
    $r->route('/oauth/token')->to( controller => 'OAuth', action => 'token' );

    $r->route('/protected_resource')->to( controller => 'Root', action => 'protected_resource' );
}

1;
