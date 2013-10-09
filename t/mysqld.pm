package mysqld;
use FindBin;
use Path::Tiny;
use DBI;
use SQL::SplitStatement;

sub dsn {
    require Test::mysqld;
    my $mysqld = Test::mysqld->new(
        my_cnf => {
            'skip-networking' => '',
        }
    ) or die $Test::mysqld::errstr;

    my $dbh = DBI->connect($mysqld->dsn, 'root', undef);
    my $schema_file = path("$FindBin::Bin/../etc/sample_schema.sql");
    my $schema_sql = $schema_file->slurp();
    my $initial_sql = <<"SQL";
USE test;
$schema_sql
SQL
    my $splitter = SQL::SplitStatement->new(
        keep_terminator      => 1,
        keep_comments        => 0,
        keep_empty_statement => 0,
    );
    for ( $splitter->split($initial_sql) ) {
        $dbh->do($_) or die( $dbh->errstr );
    }
    $mysqld->dsn;
};

1;
