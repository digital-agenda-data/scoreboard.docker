#!/bin/bash
echo "Checking geoip with key ${GEOIP_KEY}"

if [ ! -z "$GEOIP_KEY" ]; then
  # key set, check existing files

  COUNTRY_FILE=/usr/share/geoip/GeoLite2-Country.mmdb
  LAST_UPDATE=/usr/share/geoip/last_update
 
  # if files do not exist or last check file does not exist or last checked more than 30 days ago 
  if [ ! -f $COUNTRY_FILE ] || [ ! -f $LAST_UPDATE ] || [ `find $LAST_UPDATE -mtime +30 | egrep '.*'` ]; then 
    echo Updating geoip database
    set -x && mkdir -p /usr/share/geoip \
    && wget -O /tmp/country.tar.gz "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country&license_key=${GEOIP_KEY}&suffix=tar.gz" \
    && tar xf /tmp/country.tar.gz -C /usr/share/geoip --strip 1 \
    && wget -O /tmp/city.tar.gz "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-City&license_key=${GEOIP_KEY}&suffix=tar.gz" \
    && tar xf /tmp/city.tar.gz  -C /usr/share/geoip --strip 1 \
    && touch $LAST_UPDATE \
    && ls -al /usr/share/geoip/
  fi
else
  echo "Geoip key not found! Set the GEOIP_KEY env variable to the license key obtained from https://www.maxmind.com/en/geoip2-services-and-databases"
fi

echo "Geoip done"

