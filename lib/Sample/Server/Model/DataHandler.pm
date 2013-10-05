package Sample::Server::Model::DataHandler;
use parent qw/Sample::Server::Model OAuth::Lite2::Server::DataHandler/;
use OAuth::Lite2::Model::AuthInfo;
use OAuth::Lite2::Model::AccessToken;
use String::Random qw/random_regex/;

sub new {
    my ($class, %args) = @_;
    my $self = bless { request => undef, %args }, $class;
    $self->init;
    $self;
}

sub get_user_id {
    my ($self, $user_name, $password) = @_;
    my $user = $self->db->single('user', { user_name => $user_name, password => $password });
    return unless $user;
    return $user->id;
}

sub create_or_update_auth_info {
    my $self = shift;
    my %args = Params::Validate::validate(@_, {
        client_id   => 1,
        user_id     => 1,
        scope       => { optional => 1 },
    });

    my $auth_info = $self->db->single('auth_info', { client_id => $args{client_id}, user_id => $user_id });
    unless($auth_info) {
        $auth_info = $self->db->insert('auth_info', {
            client_id => $args{client_id},
            user_id => $args{user_id},
            # scope => $args{scope} || '',
        });
    }

    my $attr = {
        id => $auth_info->id,
        client_id => $auth_info->client_id,
        user_id => $auth_info->user_id,
        scope => $auth_info->scope,
        refresh_token => $auth_info->refresh_token,
    };
    return OAuth::Lite2::Model::AuthInfo->new($attr);
}

sub create_or_update_access_token {
    my $self = shift;
    my %attr = Params::Validate::validate(@_, {
        auth_info   => 1,
    });
    my $access_token = $self->db->single('access_token', {
        auth_id => $attr{auth_info}->id,
    });
    unless($access_token) {
        $access_token = $self->db->insert('access_token', {
            auth_id => $attr{auth_info}->id,
            token => random_regex('[0-9a-zA-Z]{32}'),
            expires_in => 60 * 60,
            created_on => time(),
        });
    };

    return OAuth::Lite2::Model::AccessToken->new({
        auth_id => $access_token->auth_id,
        token => $access_token->token,
        expires_in => $access_token->expires_in,
        created_on => $access_token->created_on,
    });
}

sub validate_client {
    my ($self, $client_id, $client_secret, $grant_type) = @_;
    my $client = $self->db->single('client', { client_id => $client_id });
    return unless $client;
    return unless $client->client_secret eq $client_secret;
    return 1;
}

sub get_access_token {
    my ($self, $token) = @_;
    my $access_token = $self->db->single('access_token', { token => $token });
    return unless $access_token;
    return OAuth::Lite2::Model::AccessToken->new({
        auth_id => $access_token->auth_id,
        token => $access_token->token,
        expires_in => $access_token->expires_in,
        created_on => $access_token->created_on,
    });
}

sub get_auth_info_by_id {
    my ( $self, $auth_id ) = @_;
    my $auth_info = $self->db->single( 'auth_info', { id => $auth_id } );
    return unless $auth_info;
    return OAuth::Lite2::Model::AuthInfo->new({
        id => $auth_info->id,
        client_id => $auth_info->client_id,
        user_id => $auth_info->user_id,
        scope => $auth_info->scope,
        refresh_token => $auth_info->refresh_token,
    });
}

1;
