#!/bin/bash

set -x 

wget -O /tmp/country.tar.gz http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz 
tar xf /tmp/country.tar.gz -C /usr/share/geoip --strip 1 
wget -O /tmp/city.tar.gz http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz 
tar xf /tmp/city.tar.gz  -C /usr/share/geoip --strip 1 
ls -al /usr/share/geoip/

