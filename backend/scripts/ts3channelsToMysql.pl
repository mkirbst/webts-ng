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
# mysql> CREATE TABLE IF NOT EXISTS `ts3db`.`ts3channels` (`CHANNELID` INT NOT NULL , `CHANNELNAME` VARCHAR(64) NOT NULL , `MINUTES` BIGINT, PRIMARY KEY (`CHANNELID`)) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8;
# mysql> FLUSH PRIVILEGES;
# mysql> QUIT;

use strict;
use Net::Telnet;
use DBI;


## my $LOGFILE  = "ts3channelsToMysql.log"; 		# watch this file for additional debug output if the script can't poll information from the TS3 server

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
sleep 8; # wait for other query plugins to finish

## my $telnet = new Net::Telnet ( Timeout=>10, Errmode=>'die', Input_log => $LOGFILE);
my $telnet = new Net::Telnet ( Timeout=>10, Errmode=>'die');
$telnet->open(Host => $TS3_HOSTNAME, Port => $TS3_HOSTPORT);
$telnet->waitfor('/Welcome */i');

$telnet->print("login $TS3_QUERYLOGIN $TS3_QUERYPASSWORD");
$telnet->waitfor('/error id=0 msg=ok/i');
$telnet->print('use sid=1');
$telnet->waitfor('/error id=0 msg=ok/i');
$telnet->print("channellist");
my @TELNETRAW = $telnet->waitfor('/error id=0 msg=ok/i');
$telnet->close;

sleep 8; ## wait for script to safely disconnect from ts server

##############################
## string modification part ##
##############################

my @channels = split( '\|' , @TELNETRAW[0]);

my $CHANNELID      = "";
my $CHANNELNAME      = "";
my $CHANNELUSERCOUNT = 0;

#### open connection to database
my ($db_user, $db_name, $db_pass) = ($DB_USERNAME, $DB_DATABASE, $DB_PASSWORD);
my $dbh = DBI->connect("DBI:mysql:database=$db_name", $db_user, $db_pass);

foreach my $channel ( @channels )
{
                my @channelline = split(' ', $channel);
                foreach my $channelpart ( @channelline )
                {
                        ## process channel_id
                        if ($channelpart =~ m/^cid=/)
                        {
                                # remove "cid=" from cid=42 
                                my @TMPCHANNELID = split("=", $channelpart);
                                $CHANNELID = @TMPCHANNELID[1]
                        }
                        ## process channel_nickname
                        if ($channelpart =~ m/^channel_name=/)
                        {
                                # remove trailing channel_name= from string
                                my @TMPCHANNELNAME = split("=", $channelpart);
                                $CHANNELNAME = @TMPCHANNELNAME[1];
				
				## TS3 server replaces whitespaces in player or channel names with \s, we replace this by underscore
				$CHANNELNAME =~ s/\\s/_/g;		

                                ## Umlaute - special chars in german language
                                $CHANNELNAME =~ s/Ä/Ae/g;
                                $CHANNELNAME =~ s/Ö/Oe/g;
                                $CHANNELNAME =~ s/Ü/Ue/g;
                                $CHANNELNAME =~ s/ä/ae/g;
                                $CHANNELNAME =~ s/ö/oe/g;
                                $CHANNELNAME =~ s/ü/ue/g;
                                $CHANNELNAME =~ s/ß/ss/g;
		
                                ## clean up TS names from st**id id**ts who use every special char UTF16 has available in their TS names ....
                                $CHANNELNAME =~ s/[^a-zA-Z0-9_-]/_/g;
                        }

			## process usercount per channel
                	if ($channelpart =~ m/^total_clients=/)
                	{
                        	# remove trailing channel_name= from string
                        	my @TMPCHANNELUC = split("=", $channelpart);
                        	$CHANNELUSERCOUNT = @TMPCHANNELUC[1];

                        	if($CHANNELID == 1)     # subtract 1 for query client as query client joins default channel
                        	{
                                	$CHANNELUSERCOUNT -= 1;
				}
                	}


                }

		if(!($CHANNELNAME =~ m/spacer/))
		{
                	## INSERT INTO DATABASE
                	my $sth = $dbh->prepare('INSERT INTO ts3channels (CHANNELID, CHANNELNAME, MINUTES) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE CHANNELNAME=? ,MINUTES=MINUTES+? ');
                	$sth->execute($CHANNELID, $CHANNELNAME, $CHANNELUSERCOUNT, $CHANNELNAME, $CHANNELUSERCOUNT) or die $DBI::errstr;;
                	$sth->finish();
		}
}
## disconnect from database
$dbh->disconnect();

                


               
