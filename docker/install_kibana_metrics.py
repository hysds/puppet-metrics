#!/usr/bin/env python
import os, sys, json, requests, time
from requests.exceptions import ConnectionError


ES_URL = "http://metrics-elasticsearch:9200"


def install(cfg_file):
    """Install kibana config."""

    with open(cfg_file) as f:
        cfg = json.load(f)

    url = "%s/kibana-int/dashboard/%s" % (ES_URL, cfg['title'])
    r = requests.head(url)
    if r.status_code == 200:
        print("%s already installed." % cfg['title'])
        return
    elif r.status_code == 404:
        data = {
            'user': 'guest',
            'group': 'guest',
            'title': cfg['title'],
            'dashboard': json.dumps(cfg),
        }
        r2 = requests.put(url, data=json.dumps(data))
        r2.raise_for_status()
        print("Installed %s." % cfg_file)
    else: r.raise_for_status()

     
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
    install('/tmp/Job_Metrics.json')
    install('/tmp/Worker_Metrics.json')
