#!/usr/bin/python
import os
import glob
import time
import sys
import urllib
import urllib2
import csv
import StringIO
import zipfile
from subprocess import call
import shutil
import logging

SPARQL_ENDPOINT=os.environ.get('SPARQL_ENDPOINT', "http://localhost:8891/sparql")
ISQL_HOST=os.environ.get('ISQL_HOST', "virtuoso")
ISQL_PORT=os.environ.get('ISQL_PORT', "1111")
ISQL_USER=os.environ.get('ISQL_USER', "dba")
ISQL_PASSWORD=os.environ.get('ISQL_PASSWORD',"secret")
OUTPUT_DIR=os.environ.get('OUTPUT_DIR', "/var/local/scoreboardtest/download")

QUERY_LIST="""
PREFIX dc: <http://purl.org/dc/terms/>
PREFIX qb: <http://purl.org/linked-data/cube#>
SELECT DISTINCT ?dataset, max(str(?last_updated)) as ?modified, ?g WHERE {
  graph ?g {
    ?obs a qb:Observation;
    qb:dataSet ?dataset.
  }
  OPTIONAL {?dataset dc:modified ?last_updated}
}
GROUP BY ?dataset ?g
LIMIT 100
"""
QUERY_DUMP="""
PREFIX qb: <http://purl.org/linked-data/cube#>
PREFIX sdmx-measure: <http://purl.org/linked-data/sdmx/2009/measure#>
PREFIX dad-prop: <http://semantic.digital-agenda-data.eu/def/property/>
SELECT DISTINCT ?observation ?time_period ?ref_area ?indicator ?breakdown ?unit_measure ?value ?flag ?note WHERE {
  ?observation
    a qb:Observation ;
    qb:dataSet <%s> ;
    dad-prop:breakdown ?breakdown_uri ;
    dad-prop:indicator ?indicator_uri ;
    dad-prop:ref-area ?ref_area_uri ;
    dad-prop:time-period ?time_period_uri ;
    dad-prop:unit-measure ?unit_measure_uri .
    OPTIONAL {?observation sdmx-measure:obsValue ?value}
    OPTIONAL {?observation dad-prop:flag ?flag_uri}
    OPTIONAL {?observation dad-prop:note ?note}
    OPTIONAL {?breakdown_uri skos:notation ?breakdown}
    OPTIONAL {?indicator_uri skos:notation ?indicator}
    OPTIONAL {?ref_area_uri skos:notation ?ref_area}
    ?time_period_uri skos:notation ?time_period .
    OPTIONAL {?flag_uri skos:notation ?flag}
    OPTIONAL {?unit_measure_uri skos:notation ?unit_measure}
}
"""

sparql_params = urllib.urlencode({
    'default-graph-uri': '',
    'query': QUERY_LIST,
    'format': 'text/csv',
    'timeout': 0
})
result = urllib2.urlopen(SPARQL_ENDPOINT, data=sparql_params)
print 'Reading datasets from ' + SPARQL_ENDPOINT
reader = csv.reader(StringIO.StringIO(result.read()), delimiter=',')
reader.next()
for row in reader:
    # (dataset_uri, last_updated, graph_uri)
    try:
        dataset_uri = row[0]
        dataset=dataset_uri.split('/')[-1]
        with open(OUTPUT_DIR+'/'+dataset+'.last_updated', 'w') as timestamp:
            timestamp.write(row[1])
        # export TTL using isql command
        with open('isql.script', 'w') as f:
            f.write("dump_one_graph('{0}', '{1}/{2}', 5000000000);".format(row[2], OUTPUT_DIR, dataset))

        print 'Exporting ttl for %s' % dataset
        call(["/usr/bin/isql-vt", ISQL_HOST":"ISQL_PORT, ISQL_USER, ISQL_PASSWORD, "isql.script"])
        #call(["isql", ISQL_PORT, ISQL_USER, ISQL_PASSWORD, "isql.script"])
        #print 'Zipping %s.ttl' % dataset
        #zf = zipfile.ZipFile(OUTPUT_DIR +'/' + "%s.ttl.zip" % (dataset), "w", zipfile.ZIP_DEFLATED)
        #files = glob.glob(OUTPUT_DIR +'/' + dataset + '*.ttl')
        #for filename in files:
        #    zf.write(filename, os.path.split(filename)[-1])
        #zf.close()
        # export CSV
        sparql_csv_params = urllib.urlencode({
            'default-graph-uri': '',
            'query': QUERY_DUMP%dataset_uri,
            'format': 'text/csv',
            'timeout': 0
        })
        print 'Exporting csv for %s' % dataset
        dataset_csv = urllib2.urlopen(SPARQL_ENDPOINT, data=sparql_csv_params)
        csv_filename = OUTPUT_DIR +'/' + dataset + '.csv'
        with open(csv_filename, 'wb') as csvfile:
            while True:
                chunk = dataset_csv.read(64*1024)
                if not chunk: break
                csvfile.write(chunk)
        print 'Zipping %s' % csv_filename
        zf = zipfile.ZipFile(csv_filename + ".zip", "w", zipfile.ZIP_DEFLATED)
        files = glob.glob(csv_filename)
        for filename in files:
            zf.write(filename, os.path.split(filename)[-1])
        zf.close()
        # generate TSV from CSV
        print 'Exporting tsv for %s' % dataset
        tsv_filename = OUTPUT_DIR +'/' + dataset + '.tsv'
        with open(csv_filename, 'r') as csvfile:
            csv_reader = csv.reader(csvfile, delimiter=',')
            with open(tsv_filename, 'wb') as tsvfile:
                for row in csv_reader:
                    tsvfile.write("\t".join(row) + "\n")
        print 'Zipping %s' % tsv_filename
        zf = zipfile.ZipFile(tsv_filename + ".zip", "w", zipfile.ZIP_DEFLATED)
        files = glob.glob(tsv_filename)
        for filename in files:
            zf.write(filename, os.path.split(filename)[-1])
        zf.close()
    except Exception, e:
        logging.exception(e)


