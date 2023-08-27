### WSJTX_Log

A simple script to keep Cloudlog in synch with WSJTX's logbook. As soon as a qso is saved in WSJTX it is sent to Cloudlog as well. 
Additionally the current frequency and mode are send to Cloudlog, if you want todo live logging, directly in Cloudlog. 

## Installation
 copy the script and this config file in a directory
 add the script in your crontab, so it is called at system start
 add the logfile to /etc/logrotate.d/rsyslog

## Systemd installation
 - create unprivileged user `useradd -m -r -d /opt/wsjtx_log -g nobody -s /usr/bin/nologin wsjtxlog`
 - copy script and config into `cp wsjtx_log.pl wsjtx_log.conf /opt/wsjtx_log/`
 - copy service `cp wsjtx_log.service /lib/systemd/system`
 - reload systemd `systemctl daemon-reload`
 - run service `systemctl start wsjtx_log`
 - for logs check journal `journalctl -fu wsjtx_log`
 - for autostart after reboot use `systemd enable wsjtx_log`
