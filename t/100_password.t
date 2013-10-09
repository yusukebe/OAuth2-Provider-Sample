use strict;
use FindBin;
use lib "$FindBin::Bin";
use Test::More;
use Plack::Test;
use Mojo::Server::PSGI;
use HTTP::Request::Common;
use OAuth::Lite2::Util qw/build_content/;
use JSON qw/decode_json/;

BEGIN {
    $ENV{SMAPLE_CONIFG} = "$FindBin::Bin/config.pl";
    use_ok('Sample::Server::Model');
    use_ok('Sample::Server::Web');
}

my $psgi = Mojo::Server::PSGI->new( app => Sample::Server::Web->new );
my $app = $psgi->to_psgi_app;
my $test = Plack::Test->create($app);

subtest 'route' => sub {
    my $res;
    $res = $test->request(GET '/admin');
    is $res->code, 200;
    $res = $test->request(GET '/protected_resource');
    is $res->code, 404;
};

subtest 'oauth' => sub {
    my ($req, $res);

    my ($user_name, $password) = ('user', 'password');
    $res = $test->request(POST '/admin/add_user', [ user_name => $user_name, password => $password ]);
    is $res->code, 200;
    my $model = Sample::Server::Model->new;
    my $user = $model->db->single('user', { user_name => $user_name });
    ok $user;
    is $user->password, $password;

    my ($client_name, $client_id, $client_secret) = ('client', undef, undef);
    $res = $test->request(POST '/admin/add_client', [ client_name => 'client' ] );
    is $res->code, 200;
    my $model = Sample::Server::Model->new;
    my $client = $model->db->single('client', { client_name => $client_name } );
    ok $client;
    $client_secret = $client->client_secret;
    $client_id = $client->client_id;

    my $param = build_content({
        client_id => $client_id,
        client_secret => $client_secret,
        username => $user_name,
        password => $password,
        grant_type => 'password',
    });
    $res = $test->request(GET "/oauth/token?$param");
    is $res->code, 200;
    my $data = decode_json($res->content);
    my $access_token = $data->{access_token};
    ok $access_token;
    
    $req = GET '/protected_resource';
    $req->header( Authorization => sprintf(q{OAuth %s}, $access_token) );
    $res = $test->request($req);
    is $res->code, 200;
};

done_testing();
