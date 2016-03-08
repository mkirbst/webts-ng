The scripts in this directory have to run periodically,
i advise to run them as cronjob's. For example:

# email to the user the crontab file belongs to (unless redirected).
#
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
#
# For more information see the manual pages of crontab(5) and cron(8)
# 
# m h  dom mon dow   command

*/1 * * * *     /usr/bin/nice -n 19 /home/ts3/scripts/ts3channelsToMysql.pl
*/1 * * * *     /usr/bin/nice -n 19 /home/ts3/scripts/ts3usersToMysql.pl
*/5 * * * *     /usr/bin/nice -n 19 /home/ts3/scripts/ts3aliases.pl > /var/www/ts3/aliases.txt


