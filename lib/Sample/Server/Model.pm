package Sample::Server::Model;
use DBI;
use Teng;
use Teng::Schema::Loader;
use String::Random;

sub new {
    my ($class, %opt) = @_;
    my $self = bless {}, $class;
    return $self;
}

sub db {
    my $self = shift;
    return $self->{db} if $self->{db};
    my $dbh = DBI->connect(
        'dbi:mysql:oauth2_sample', 'root', undef,
        { mysql_enable_utf8 => 1 }
    );
    my $db = Teng::Schema::Loader->load(
        dbh => $dbh,
        namespace => 'Sample::DB',
    );
    $self->{db} = $db;
    return $db;
}

1;
