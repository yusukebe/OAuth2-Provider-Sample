package Sample::Server::Web::Controller::Admin;
use Mojo::Base 'Mojolicious::Controller';
use Mojolicious::Validator;
use Sample::Server::Model;
use String::Random qw/random_regex/;
use Try::Tiny;

sub index {
    my $self = shift;
    my $model = Sample::Server::Model->new;
    my @clients = $model->db->search('client', {}, { order_by => 'id' });
    $self->stash->{clients} = \@clients;
    my @users = $model->db->search('user', {}, { order_by => 'id' });
    $self->stash->{users} = \@users;
    $self->render('/admin');
}

sub add_client {
    my $self = shift;
    my $client_name = $self->req->param('client_name');
    return $self->redirect_to('/admin') unless $client_name;

    my $validation = Mojolicious::Validator->new->validation;
    $validation->input({ client_name => $client_name });
    $validation->required('client_name')->regex(qr/^[0-9a-zA-Z_]/)->size(1,20);
    if($validation->error('client_name')) {
        $self->stash->{error_message} = 'client_name must be under 20 words and shoud be [0-9a-z-A-Z_]';
        return $self->render('/admin');
    }

    my $model = Sample::Server::Model->new;
    
    try {
        $model->db->insert('client', {
            client_name => $client_name,
            client_id => random_regex('[0-9a-zA-Z]{16}'),
            client_secret => random_regex('[0-9a-zA-Z]{32}'),
        });
    }catch{
        warn $_;
    };
    
    $self->redirect_to('/admin');
}

sub add_user {
    my $self = shift;
    my $user_name = $self->req->param('user_name');
    my $password = $self->req->param('password');
    return $self->redirect_to('/admin') unless $user_name && $password;

    my $validation = Mojolicious::Validator->new->validation;
    $validation->input({
        user_name => $user_name,
        password => $password,
    });
    $validation->required('user_name')->regex(qr/^[0-9a-zA-Z_]/)->size(1,20);
    $validation->required('password')->regex(qr/^[0-9a-zA-Z_]/)->size(6,20);
    if($validation->error('user_name')) {
        $self->stash->{error_message} = 'user_name must be under 20 words and shoud be [0-9a-z-A-Z_]';
        return $self->render('/admin');
    }
    if($validation->error('password')) {
        $self->stash->{error_message} = 'password must be 6 - 20 words and shoud be [0-9a-z-A-Z_]';
        return $self->render('/admin');
    }

    my $model = Sample::Server::Model->new;
    
    try {
        $model->db->insert('user', {
            user_name => $user_name,
            password => $password,
        });
    }catch{
        warn $_;
    };
    
    $self->redirect_to('/admin');
}

1;
