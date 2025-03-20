#!/usr/bin/env bash
set -ex

# Wait for the service to be up
avn service wait demo-postgres

# Get the connection string
DB_SERVICE_URI=$(avn service get demo-postgres --format '{service_uri}')

# Initialize database publications, tables & data
psql "$DB_SERVICE_URI" -f ./db_init.sql

# Restart the connector
avn service connector restart franz kafka-pg-connector
avn service connector restart-task franz kafka-pg-connector 0
