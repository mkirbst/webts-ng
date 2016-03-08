#!/usr/bin/perl

# Teamspeak 3 Users Top10 per time on server
# this script has to be executed every 5 minutes and polls the users currently on the server
# if you want another timespan than 5 minutes, please modify the mysql statement at the end
#
# Please check that you have a sufficient perl environment on your server and you have installed 
# the Net::Telnet module. For example in ubuntu you have to type:
# $ sudo apt-get install libnet-telnet-perl
#
# You also need a mysql database, in which are the values for your ts3users are stored. 
# THE PASSWORD IS A EXAMPLE, PLEASE CHOOSE AN OWN, SECURE PASSWORD AND SET IT UP IN BOOTH FILES, THE PERL AND PHP FILE.. 
# SEE: https://www.schneier.com/blog/archives/2014/03/choosing_secure_1.html
# 
# ---- howto create approriate mysql database ----
# create a query login name+password in your TS3 server an put it into line 31 and also 
# a appropriate database as following: (my testdatabase here is called ts3db and the new table is named ts3top)
#
# $ mysql -u root -p
# mysql> CREATE DATABASE IF NOT EXISTS ts3db;
# mysql> GRANT ALL ON *.* TO 'ts3queryuser'@'localhost' IDENTIFIED BY 'mysqlpassword';
# mysql> CREATE TABLE IF NOT EXISTS `ts3db`.`ts3top` (`CLDBID` INT NOT NULL , `CLNAME` VARCHAR(64) NOT NULL , `Minutes` BIGINT, PRIMARY KEY (`CLDBID`), platform VARCHAR(32), conncount BIGINT, country VARCHAR(2), online SMALLINT ) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8;
# mysql> FLUSH PRIVILEGES;
# mysql> QUIT;

########################################################################################################################################
## 20150325181100: PART II - Logging also the nick names, every user uses
# create appropriate table:
#
# CREATE TABLE ts3aliases (id INT NOT NULL, alias VARCHAR(128) NOT NULL, firstseen TIMESTAMP, lastseen TIMESTAMP, Minutes BIGINT, PRIMARY KEY(id, alias));
#
# There are only 3 additional lines at the end of this script, as it uses the same database handler
# The tables primary key consists of the TS ID and the username, so every time the database sees a new id+username combination,
# a new database entry is created, ensuring to log the nicks of every user, represented by his or her TS ID,
# otherwise only lastseen attribute is updated to the actual timestamp NOW() 
#######################################################################################################################################
## 20160229: Part III - Log also platform, country, connection-count
# clientinfo clid=11
# client_platform=Linux 
# client_country=DE
# client_totalconnections=14
#######################################################################################################################################

use strict;
use Net::Telnet;
use DBI;

my $LOGFILE  = "ts3usersToMysql.log"; 		# watch this file for additional debug output if the script can't poll information from the TS3 server

# TS3 server variables
my $TS3_HOSTNAME = "127.0.0.1";
my $TS3_HOSTPORT = "10011";
my $TS3_QUERYLOGIN = "queryuser";
my $TS3_QUERYPASSWORD = "querypassword";	# replace this example with your valid TS3 queryadmin server password

# mysql variables			
my $DB_DATABASE	= "ts3db";
my $DB_USERNAME = "ts3queryuser";
my $DB_PASSWORD = "mysqlpassword";


#################
## telnet part ##
#################

my $telnet = new Net::Telnet ( Timeout=>10, Errmode=>'die', Input_log => $LOGFILE);
$telnet->open(Host => $TS3_HOSTNAME, Port => $TS3_HOSTPORT);
$telnet->waitfor('/Welcome */i');

$telnet->print("login $TS3_QUERYLOGIN $TS3_QUERYPASSWORD");
$telnet->waitfor('/error id=0 msg=ok/i');
$telnet->print('use sid=1');
$telnet->waitfor('/error id=0 msg=ok/i');
$telnet->print("clientlist");
my @TELNETRAW = $telnet->waitfor('/error id=0 msg=ok/i');

##############################
## string modification part ##
##############################

my @clients = split( '\|' , @TELNETRAW[0]);

my $CLDBID      = "";
my $CLNAME      = "";

my $CLIDS	= "";
my $CLID	= 0;

my $CLPLATFORM 	= "";
my $CLCONNCOUNT = 0;
my $CLCOUNTRY	= "";


#### open connection to database
##>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#first mark all users as offline
my ($db_user, $db_name, $db_pass) = ($DB_USERNAME, $DB_DATABASE, $DB_PASSWORD);
my $dbh = DBI->connect("DBI:mysql:database=$db_name", $db_user, $db_pass);

my $sthsetoffline = $dbh->prepare('UPDATE ts3top SET online = 0;');
$sthsetoffline->execute() or die $DBI::errstr;;
$sthsetoffline->finish();


foreach my $client ( @clients )
{
        # process client only if clienttype 0 - normal teamspeak client
        if ($client =~ m/client_type=0/)
        {

#		printf($client."\n");

                my @clientline = split(' ', $client);
                foreach my $clientpart ( @clientline )
                {

                       ## process client_datbase_id
                        if ($clientpart =~ m/^client_database_id=/)
                        {
                                # remove "client_database_id=" from client_database_id=42 
                                my @TMPCLDBID = split("=", $clientpart);
                                $CLDBID = @TMPCLDBID[1]
                        }
 
                        ## process client_nickname
                        if ($clientpart =~ m/^client_nickname=/)
                        {
                                # remove trailing client_nickname= from string
                                my @TMPCLNAME = split("=", $clientpart);
                                $CLNAME = @TMPCLNAME[1];

                                ## TS3 server replaces whitespaces in player or channel names with \s, we replace this by underscore
                                $CLNAME =~ s/\\s/_/g;

                                ## clean up TS names from st**id id**ts who use every special char UTF16 has available in their TS names ....
                                $CLNAME =~ s/[^a-zA-Z0-9_-]/_/g;
                        }


                        ## process clid and user details (county, connection count, platform)
                        if ($clientpart =~ m/^clid=/)
                        {
                                # remove "clid=" from clid=42 
                                my @TMPCLID = split("=", $clientpart);
                                $CLID = @TMPCLID[1];
				printf($CLID."\n");

				$telnet->print("clientinfo clid=".$CLID);
				my @TELNETUSERRAW = $telnet->waitfor('/error id=0 msg=ok/i');
				my @clientinfos = split( ' ' , @TELNETUSERRAW[0]);

				foreach my $clientinfo ( @clientinfos )
				{
##					printf($clientinfo."\n");
		                        if ($clientinfo =~ m/^client_country=/)
                        		{
                                		# remove "client_country=" from client_country=DE 
                                		my @TMPCLCOUNTRY = split("=", $clientinfo);
                                		$CLCOUNTRY = @TMPCLCOUNTRY[1];

		                                ## TS3 server replaces whitespaces with \s, we replace this by underscore
                                		$CLCOUNTRY =~ s/\\s/_/g;
                                		$CLCOUNTRY =~ s/[^a-zA-Z0-9_-]/_/g;

#						printf($CLCOUNTRY."\n");
                        		}
		                        if ($clientinfo =~ m/^client_platform=/)
                        		{
                                		# remove "client_platform=" from client_platform=Linux 
                                		my @TMPCLPLATFORM = split("=", $clientinfo);
                                		$CLPLATFORM = @TMPCLPLATFORM[1];

		                                ## TS3 server replaces whitespaces with \s, we replace this by underscore
                                		$CLPLATFORM =~ s/\\s/_/g;
                                		$CLPLATFORM =~ s/[^a-zA-Z0-9_-]/_/g;
                        		}
		                        if ($clientinfo =~ m/^client_totalconnections=/)
                        		{
                                		# remove "client_totalconnections=" from client_totalconnections=12 
                                		my @TMPCLCONNCOUNT = split("=", $clientinfo);
                                		$CLCONNCOUNT = @TMPCLCONNCOUNT[1];
                        		}
				}
			}                        
                }

                ## INSERT INTO DATABASE
                my $sth = $dbh->prepare('INSERT INTO ts3top (CLDBID, CLNAME, Minutes, platform, conncount, country, online) VALUES (?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE CLNAME=? ,Minutes=Minutes+1, platform=?, conncount=?, country=?, online=?');
                $sth->execute($CLDBID, $CLNAME, 1,$CLPLATFORM, $CLCONNCOUNT, $CLCOUNTRY, 1, $CLNAME, $CLPLATFORM, $CLCONNCOUNT, $CLCOUNTRY, 1) or die $DBI::errstr;;
                $sth->finish();

		###################################################################################################
                ## Part II - Log all alias names a user uses:
                my $sthaliases = $dbh->prepare('INSERT INTO ts3aliases (id, alias, firstseen, lastseen, Minutes) VALUES (?, ?, NOW(), NOW(), ?) ON DUPLICATE KEY UPDATE firstseen = firstseen, lastseen = NOW(), Minutes=Minutes+1 ');                
                $sthaliases->execute($CLDBID, $CLNAME, 1) or die $DBI::errstr;;
      		$sthaliases->finish();
                ## /Part II
                ###################################################################################################
        }
}

####CLEANUP

##close telnet session
$telnet->close;

## disconnect from database
$dbh->disconnect();
##>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><
                


               
