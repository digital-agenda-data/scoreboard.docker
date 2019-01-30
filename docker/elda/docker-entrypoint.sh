#!/bin/bash

cd $ELDA_HOME

if [ -n "$SPARQL_ENDPOINT" ] && [ $(grep -c SPARQL_ENDPOINT /var/local/elda/webapps/elda/specs/scoreboard.ttl) -gt 0 ]; then
    sed -i "s#SPARQL_ENDPOINT#$SPARQL_ENDPOINT#g" /var/local/elda/webapps/elda/specs/scoreboard.ttl
fi

exec $@


