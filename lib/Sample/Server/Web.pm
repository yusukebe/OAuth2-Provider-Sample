package Sample::Server::Web;
use Mojo::Base 'Mojolicious';
use Plack::Middleware::Auth::OAuth2::ProtectedResource;
use Sample::Server::Model::DataHandler;
use Sample::Server::Model;
use Mojo::Server::PSGI;
use Try::Tiny;

sub startup {
    my $self = shift;

    $self->hook(
        before_dispatch => sub {
            my $c = shift;
            my $middleware =
                Plack::Middleware::Auth::OAuth2::ProtectedResource->new(
                    data_handler => 'Sample::Server::Model::DataHandler',
                    app => {},
                );
            try {
                $middleware->call($c->req->env);
            }catch{
                $self->log->warn($_);
            };
            if(my $user_id = $c->req->env->{REMOTE_USER}) {
                my $user = Sample::Server::Model->new->db->single('user', { id => $user_id });
                $c->stash->{user} = $user->get_columns();
            }else{
                $c->stash->{user} = undef;
            }
        },
    );

    $self->helper(
        render_not_found_x => sub {
            my $c = shift;
            $c->res->code(404);
            $c->render(json => { error => { message => 'not found' } });
        }
    );

    my $r = $self->routes;
    $r->namespaces([qw/Sample::Server::Web::Controller/]);

    $r->route('/')->to( controller => 'Root', action => 'index' );
    $r->route('/admin')->to( controller => 'Admin', action => 'index' );
    $r->post('/admin/add_user')->to( controller => 'Admin', action => 'add_user' );
    $r->post('/admin/add_client')->to( controller => 'Admin', action => 'add_client' );
    $r->get('/oauth/authorize')->to( controller => 'OAuth', action => 'authorize' );
    $r->route('/oauth/token')->to( controller => 'OAuth', action => 'token' );
    $r->route('/protected_resource')->to( controller => 'Root', action => 'protected_resource' );
}

1;
