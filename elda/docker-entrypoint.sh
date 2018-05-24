#!/bin/bash

cd $ELDA_HOME

if [ -n "$ELDA_BASE_URL" ] && [ $(grep -c ELDA_BASE_URL /var/local/elda/webapps/elda/specs/scoreboard.ttl) -gt 0 ]; then
    
    sed -i "s/ELDA_BASE_URL/$ELDA_BASE_URL/g" /var/local/elda/webapps/elda/specs/scoreboard.ttl 


fi


exec $@


