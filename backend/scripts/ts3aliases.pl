#!/usr/bin/perl

use strict;
use DBI;

my ($db_user, $db_name, $db_pass) = ('ts3queryuser', 'ts3db', 'querypassword');

# open connection to database
my $dbh = DBI->connect("DBI:mysql:database=$db_name", $db_user, $db_pass);

printf("firstseen\t\tlastseen\t\tid\talias\t\t".localtime()."\n\n");
my $sth = $dbh->prepare(' SELECT firstseen,lastseen,dup.id,alias FROM ts3aliases INNER JOIN (SELECT id FROM ts3aliases GROUP BY id HAVING COUNT(id) > 1 ORDER BY lastseen DESC) dup ON ts3aliases.id = dup.id ORDER BY id DESC,lastseen DESC; ');

$sth->execute() or die $DBI::errstr;;

# FETCHROW ARRAY

my @results;
my $cleanname;

while (@results = $sth->fetchrow()) 
{
	##	print $results[0]."\n";
	print join("\t", @results)."\n";
}
$sth->finish();

## disconnect from database
$dbh->disconnect();

exit 0;
