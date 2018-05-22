from __future__ import print_function
import pysolr
import requests
import argparse


parser = argparse.ArgumentParser()
parser.add_argument(
    '--core', required=True, default='scoreboard', help='Solr core')
parser.add_argument(
    '--solr', default='http://localhost:8983/solr',
    help='Solr full url, e.g. http://localhost:8983/solr')
parser.add_argument(
    '--base-path', default='http://digital-agenda-data.eu', required=True,
    help='Plone website, e.g. http://test.digital-agenda-data.eu')

args = parser.parse_args()
solr = pysolr.Solr(args.solr + '/' + args.core, timeout=60)

# do not index these
EXCLUDE_PROPS = set(['inner_order', 'parent_order', 'uri'])

CUSTOM_PREFIX = {
    #'source_uri': '_s',
    #'notation': '_s',
    'group_notation': '_txt_en_m',
    'group_name': '_txt_en_m',  # because it is multivalued
}
EXACT_MATCH_PROPS = set(CUSTOM_PREFIX.keys())

# multiple valued
MULTIPLE_PROPS = set(['group_notation'])

# list cubes
datasets = requests.get(args.base_path + '/@@datacubesForSelect').json()

for dataset in datasets['options']:
    data = requests.get(dataset['uri'] + '/dimension_metadata').json()
    if 'indicator' not in data:
        continue
    try:
        print('Indexing %s (%d records)' % (dataset['dataset'], len(data['indicator'])))
        for indicator in data['indicator']:
            obj = {}
            obj['id'] = indicator['uri']
            obj['dataset_s'] = dataset['dataset']
            keys = set(indicator.keys())
            for prop in keys.intersection(EXACT_MATCH_PROPS):
                obj[prop + CUSTOM_PREFIX[prop]] = indicator[prop]
            for prop in keys - EXCLUDE_PROPS - EXACT_MATCH_PROPS:
                # append _txt_en by default
                obj[prop + '_txt_en'] = indicator[prop]
            solr.add([obj])
    except Exception as e:
        print(type(e))
        print(e)


