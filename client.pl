use strict;
use warnings;
use OAuth::Lite2::Client::UsernameAndPassword;
use HTTP::Request;
use LWP::UserAgent;

my $client = OAuth::Lite2::Client::UsernameAndPassword->new(
    id => 'PD7cDgndYFDcminP', # client_id
    secret => 'V2v3TtBThRU5GEmpHqaewuvtnZvtEZuU', # client_secret
    access_token_uri => 'http://localhost:5001/oauth/token', 
);

my $token = $client->get_access_token(
    username => 'yusukebe',
    password => 'hogehoge',
    scope => [qw/base/],
) or die $client->errstr;

my $access_token = $token->access_token;
print "access_token: $access_token\n";


my $req = HTTP::Request->new( GET => 'http://localhost:5001/protected_resource' );
$req->header( Authorization => sprintf(q{OAuth %s}, $access_token) );
my $agent = LWP::UserAgent->new;
my $res = $agent->request($req);
print $res->content . "\n";
