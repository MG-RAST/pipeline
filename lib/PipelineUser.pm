package PipelineUser;

use strict;
use warnings;
no warnings('once');

use DBI;
use Data::Dumper;

sub get_usercache_dbh {
    my ($host, $name, $user, $pass, $key, $cert, $ca) = @_;
    my $conn_str = "DBI:mysql:database=".$name.";host=".$host;
    if ($key && $cert && $ca) {
        $conn_str .= ";mysql_ssl=1;mysql_ssl_client_key=".$key.";mysql_ssl_client_cert=".$cert.";mysql_ssl_ca_file=".$ca;
    }
    my $dbh = DBI->connect($conn_str, $user, $pass) || die $DBI::errstr;
    return $dbh;
}

sub get_usercache_info {
    my ($dbh, $user) = @_;
    my $query = $dbh->prepare(qq(select * from User where _id=?));
    $query->execute($user);
    return $query->fetchrow_hashref;
}

1;
