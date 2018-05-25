#!/bin/bash

GIT=git@github.com:digital-agenda-data/rdf.git

source /etc/environment

if [ -z "$DEPLOY_TYPE" ] || [[ ! "$DEPLOY_TYPE" == "PROD" ]] ; then 
  exit 0
fi

if [ ! -d /var/local/rdf/codelists ]; then
  git clone $GIT /var/local/rdf
fi
  
cd /var/local/rdf/codelists
  
DIMENSIONS="indicator indicator-group breakdown breakdown-group source unit-measure"
for dimension in ${DIMENSIONS}
do
        GRAPH="<http://semantic.digital-agenda-data.eu/codelist/${dimension}/>"
        QUERY="construct {?s ?p ?o}where {graph ${GRAPH} {?s ?p ?o}}"
        curl -s --data-urlencode "format=text/plain" --data-urlencode "query=${QUERY}" http://digital-agenda-data.eu/sparql | LC_ALL=C sort -n > dad-${dimension}.nt
        curl -s --data-urlencode "format=application/x-nice-turtle" --data-urlencode "query=${QUERY}" http://digital-agenda-data.eu/sparql > dad-${dimension}.ttl
done

dimension='time-period'
QUERY="construct {?s ?p ?o} where { graph ?g { ?s ?p ?o } filter (?g in (<http://semantic.digital-agenda-data.eu/codelist/time-period/>, <http://semantic.digital-agenda-data.eu/codelist/time-period>)) }"
curl -s --data-urlencode "format=text/plain" --data-urlencode "query=${QUERY}" http://digital-agenda-data.eu/sparql | LC_ALL=C sort -n > dad-${dimension}.nt
curl -s --data-urlencode "format=application/x-nice-turtle" --data-urlencode "query=${QUERY}" http://digital-agenda-data.eu/sparql > dad-${dimension}.ttl

git add -u && git commit --quiet -m "Codelist updates" > /dev/null && git pull --rebase && git push

