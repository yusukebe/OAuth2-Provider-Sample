package Sample::Server::Model::DataHandler;
use parent qw/Sample::Server::Model OAuth::Lite2::Server::DataHandler/;
use OAuth::Lite2::Model::AuthInfo;
use OAuth::Lite2::Model::AccessToken;
use String::Random qw/random_regex/;
use Digest::MD5 qw/md5_hex/;

sub new {
    my ($class, %args) = @_;
    my $default_expires_in = delete $args{default_expires_in} || 60 * 60 * 24 * 30;
    my $self = bless {
        request => undef,
        default_expires_in => $default_expires_in,
        %args
    }, $class;
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
        client_id => 1,
        client_secret => { optional => 1 },
        user_id => { optional => 1 },
        refresh_token => { optional => 1 },
        scope => { optional => 1 },
    });
    my $client = $self->db->single('client', { client_id => $args{client_id} });
    my $token = random_regex('[0-9a-zA-Z]{32}');
    
    my $user_id;
    if( $args{refresh_token} ) {
        my $auth_info = $self->db->single('auth_info', { refresh_token => $args{refresh_token} });
        $user_id = $auth_info->user_id if $auth_info;
    }

    my $auth_info = $self->db->insert('auth_info', {
        client_id => $client->client_id,
        client_secret => $client->client_secret,
        user_id => $user_id || $args{user_id},
        refresh_token => $token,
    });
    return OAuth::Lite2::Model::AuthInfo->new({
        id => $auth_info->id,
        client_id => $auth_info->client_id,
        user_id => $auth_info->user_id,
        scope => $auth_info->scope,
        refresh_token => $auth_info->refresh_token,
    });
}

sub create_or_update_access_token {
    my $self = shift;
    my %args = Params::Validate::validate(@_, {
        auth_info => 1,
        expires_in => { optional => 1 },
    });
    my $auth_info = $args{auth_info};
    my $token = random_regex('[0-9a-zA-Z]{32}');
    my $access_token = $self->db->single('access_token', { auth_id => $args{auth_info}->id });
    if ($access_token) {
        $access_token->update({
            token => $token, expires_in => $args{expires_in} || $self->{default_expires_in},
            created_on => time(),
        });
    } else {
        $access_token = $self->db->insert('access_token',
            {
                auth_id => $auth_info->id,
                token => $token,
                expires_in => $args{expires_in} || $self->{default_expires_in},
                created_on => time(),
            }
        );
    }
    return OAuth::Lite2::Model::AccessToken->new({
        auth_id => $access_token->auth_id,
        token => $access_token->token,
        expires_in => $access_token->expires_in,
        created_on => $access_token->created_on,
    });
}

sub validate_client {
    my ($self, $client_id, $client_secret, $grant_type) = @_;
    my $client = $self->db->single('client', { client_id => $client_id, client_secret => $client_secret });
    return unless $client;
    return 1;
}

sub get_access_token {
    my ($self, $token) = @_;
    my $access_token = $self->db->single('access_token', { token => $token });

    if(!$access_token || time() > $access_token->created_on + $access_token->expires_in ) {
        return;
    }

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

sub get_auth_info_by_refresh_token {
    my ($self, $refresh_token) = @_;
    my $auth_info = $self->db->single( 'auth_info', { refresh_token => $refresh_token } );
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
