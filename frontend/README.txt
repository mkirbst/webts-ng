Copy content of the html folder to the root directory of your webserver.

Then create symbolic links from the munin image files to the root directory
or configure munin (in /etc/munin/munin.conf) to create the html output
also to the root of the webserver. As last step adjust the paths from the
images in the index.php.
