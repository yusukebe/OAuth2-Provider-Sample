package Sample::Server::Model;
use DBI;
use Teng;
use Teng::Schema::Loader;
use Sample;

sub new {
    my ($class, %opt) = @_;
    my $self = bless {}, $class;
    return $self;
}

sub db {
    my $self = shift;
    return $self->{db} if $self->{db};
    my $connect_info = Sample->config()->{connect_info} or die;
    my $dbh = DBI->connect(
        @$connect_info,
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
