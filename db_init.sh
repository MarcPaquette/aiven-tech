#!/usr/bin/env bash
set -ex

# Wait for the service to be up
avn service wait demo-pg

# Get the connection string
DB_SERVICE_URI=$(avn service get demo-pg --format '{service_uri_params}')

# Initialize database publications, tables & data
psql "$DB_SERVICE_URI" -f ./db_init.sql

# Restart the service
# avn 
