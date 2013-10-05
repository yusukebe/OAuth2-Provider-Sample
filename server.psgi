use strict;
use warnings;
use File::Basename;
use File::Spec;
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use Mojo::Server::PSGI;
use Sample::Server::Web;

my $psgi = Mojo::Server::PSGI->new( app => Sample::Server::Web->new );
my $app = $psgi->to_psgi_app;
$app;
