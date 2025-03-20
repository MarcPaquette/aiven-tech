#!/usr/bin/env bash

# https://aiven.io/developer/change-data-capture-mysql-apache-kafka-debezium
set -ex

avn service create demo-postgres-source \
    --service-type pg \
    --plan business-4 \
    --cloud google-europe-north1   

avn service wait demo-postgres-source

# https://aiven.io/docs/products/postgresql/get-started#connect-to-the-service
# DB_SERVICE_URI=$(avn service get demo-postgres-source --format '{service_uri_params}')
# '{'\''dbname'\'': '\''defaultdb'\'', '\''host'\'': '\''demo-postgres-source-tech-demo.f.aivencloud.com'\'', '\''password'\'': '\''AVNS_RAdhonryUwR8G4ZJ3bi'\'', '\''port'\'': '\''27218'\'', '\''sslmode'\'': '\''require'\'', '\''user'\'': '\''avnadmin'\''}'

psql 'postgres://avnadmin:AV:NS_RAdhonryUwR8G4ZJ3bi@demo-postgres-source-tech-demo.f.aivencloud.com:27218/defaultdb?sslmode=require'

https://aiven.io/docs/products/kafka/kafka-connect/howto/debezium-source-connector-pg#solve-the-error-must-be-superuser-to-create-for-all-tables-publication
https://gist.github.com/alexhwoods/4c4c90d83db3c47d9303cb734135130d

