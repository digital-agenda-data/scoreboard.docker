#!/bin/bash

cd $ELDA_HOME

if [ -n "$ELDA_SPARQL_ENDPOINT" ] && [ $(grep -c ELDA_SPARQL_ENDPOINT /var/local/elda/webapps/elda/specs/scoreboard.ttl) -gt 0 ]; then
    sed -i "s#ELDA_SPARQL_ENDPOINT#$ELDA_SPARQL_ENDPOINT#g" /var/local/elda/webapps/elda/specs/scoreboard.ttl
fi

exec $@


