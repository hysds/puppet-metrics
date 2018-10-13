#!/usr/bin/env bash
set -ex

curl --user <%= @es_user %>:<%= @es_password %> -XPOST --fail \
  localhost:5601/api/kibana/dashboards/import -H 'kbn-xsrf:true' \
  -H 'Content-type:application/json' -d @/tmp/worker_metrics.json
curl --user <%= @es_user %>:<%= @es_password %> -XPOST --fail \
  localhost:5601/api/kibana/dashboards/import -H 'kbn-xsrf:true' \
  -H 'Content-type:application/json' -d @/tmp/job_metrics.json
