#!/usr/bin/env python
import os, sys, json, requests, time
from requests.exceptions import ConnectionError


ES_URL = "http://localhost:9200"


def install(exp_file):
    """Install kibana config."""

    with open(exp_file) as f:
        exp = json.load(f)

    for doc in exp:
        es_url = "%s/.kibana/%s/%s" % (ES_URL, doc['_type'], doc['_id'])
        r = requests.post(es_url, verify=False, data=json.dumps(doc['_source']))
        r.raise_for_status()

     
if __name__ == "__main__":
    print("Waiting for ElasticSearch to start up.")
    count = 0
    while True:
        try:
            r = requests.get(ES_URL)
            print("status_code: %s" % r.status_code)
            if r.status_code == 200: break
        except ConnectionError, e: print(e)
        time.sleep(2**count)
        count += 1
    install('/tmp/export.json')
