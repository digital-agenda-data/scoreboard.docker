#!/bin/bash


 #enable cron logging
service rsyslog restart
    
    #add crontab
crontab /var/crontab.txt
chmod 600 /etc/crontab

env | awk -F "=" '{ if (index($1,"CRONTAB_")>0)  {  sub("CRONTAB_","",$0); print "export "$0; } }' > /etc/environment

exec "$@"

