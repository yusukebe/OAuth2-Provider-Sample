package Sample;
use Config::PL;

our $VERSION = '0.01';

sub config {
    my $filename = $ENV{SAMPLE_CONFIG} || 'config.pl';
    my $config = config_do $filename;
    return $config;
}

1;
