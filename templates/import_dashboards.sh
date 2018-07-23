#!/usr/bin/env bash
set -ex

# start up elasticsearch
systemctl start elasticsearch

# start up kibana
/tmp/wait-for-it.sh localhost:9200 -s -t 60 -- echo "ElasticSearch is running"
sudo -u ops /home/<%= @user %>/kibana/bin/kibana &
#echo "after kibana startup: $?"

# import dashboards
/tmp/wait-for-it.sh localhost:5601 -s -t 60 -- echo "Kibana is running"
curl --user <%= @es_user %>:<%= @es_password %> -XPOST --fail \
  localhost:5601/api/kibana/dashboards/import -H 'kbn-xsrf:true' \
  -H 'Content-type:application/json' -d @/tmp/worker_metrics.json
curl --user <%= @es_user %>:<%= @es_password %> -XPOST --fail \
  localhost:5601/api/kibana/dashboards/import -H 'kbn-xsrf:true' \
  -H 'Content-type:application/json' -d @/tmp/job_metrics.json
#echo "after second import: $?"
sleep 10

# terminate kibana
PROC_ID=$(cat /home/<%= @user %>/metrics/run/kibana.pid)
echo "Kibana running as $PROC_ID"
kill -TERM $PROC_ID
echo "after kill: $?"
echo "killed $PROC_ID"
