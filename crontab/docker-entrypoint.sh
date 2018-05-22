#!/bin/bash


 #enable cron logging
service rsyslog restart
    
    #add crontab
crontab /var/crontab.txt
chmod 600 /etc/crontab

env | awk -F "=" '{ if (index($1,"CRONTAB_")>0)  {  sub("CRONTAB_","",$0); print "export "$0; } }' >> /etc/environment
echo "export PATH=$PATH" >> /etc/environment
echo "export PYTHON_VERSION=$PYTHON_VERSION" >> /etc/environment
echo "export PYTHON_PIP_VERSION=$PYTHON_PIP_VERSION" >> /etc/environment
echo "export PYTHONPATH=$PYTHONPATH:/usr/local/lib/python2.7/site-packages/" >> /etc/environment


exec "$@"

