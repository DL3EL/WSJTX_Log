### WSJTX_Log

A simple script to keep Cloudlog in synch with WSJTX's logbook. As soon as a qso is saved in WSJTX it is sent to Cloudlog as well. 
Additionally the current frequency and mode are send to Cloudlog, if you want todo live logging, directly in Cloudlog. 

Installation:
 copy the script and this config file in a directory
 add the script in your crontab, so it is called at system start
 add the logfile to /etc/logrotate.d/rsyslog

