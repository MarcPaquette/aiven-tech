resource "aiven_pg" "demo-pg" {
  project      = var.project_name
  service_name = "demo-postgres"
  cloud_name   = "google-europe-north1"
  plan         = "business-4"
}

resource "aiven_kafka" "demo-kafka" {
  project                 = var.project_name
  cloud_name              = "google-europe-north1"
  plan                    = "business-4"
  service_name            = "demo-kafka"
  maintenance_window_dow  = "sunday"
  maintenance_window_time = "10:00:00"
  kafka_user_config {
    kafka_rest      = true
    kafka_connect   = true 
    schema_registry = true
    kafka_version   = "3.8"

    kafka {
      auto_create_topics_enable  = true
      num_partitions             = 3
      default_replication_factor = 2
      min_insync_replicas        = 2
    }

    kafka_authentication_methods {
      certificate = true
    }

  }
}

resource "aiven_kafka_connect" "demo-kafka-connect" {
  project                 = var.project_name
  cloud_name              = "google-europe-north1"
  plan                    = "business-4"
  service_name            = "demo-kafka-connect"
  maintenance_window_dow  = "sunday"
  maintenance_window_time = "10:00:00"

  kafka_connect_user_config {
    kafka_connect {
      consumer_isolation_level = "read_committed"
    }

    public_access {
      kafka_connect = false
    }
  }
}

resource "aiven_service_integration" "i1" {
  project                  = var.project_name
  integration_type         = "kafka_connect"
  source_service_name      = aiven_kafka.demo-kafka.service_name
  destination_service_name = aiven_kafka_connect.demo-kafka-connect.service_name

  kafka_connect_user_config {
    kafka_connect {
      group_id             = "connect"
      status_storage_topic = "__connect_status"
      offset_storage_topic = "__connect_offsets"
    }
  }
}

resource "aiven_kafka_connector" "kafka-pg-source" {
  project        = var.project_name
  service_name   = aiven_kafka_connect.demo-kafka-connect.service_name
  connector_name = "kafka-pg-source"

  config = {
    "name"                        = "kafka-pg-source"
    "topic.prefix"                   = "prefix" 
    "connector.class"             = "io.debezium.connector.postgresql.PostgresConnector"
    "snapshot.mode"               = "initial"
    "database.hostname"           = sensitive(aiven_pg.demo-pg.service_host)
    "database.port"               = sensitive(aiven_pg.demo-pg.service_port)
    "database.password"           = sensitive(aiven_pg.demo-pg.service_password)
    "database.user"               = sensitive(aiven_pg.demo-pg.service_username)
    "database.dbname"             = "defaultdb"
    "database.server.name"        = "replicator"
    "database.ssl.mode"           = "require"
    "include.schema.changes"      = true
    "include.query"               = true
    "table.include.list"          = "public.tab1"
    "plugin.name"                 = "pgoutput"
    "publication.autocreate.mode" = "filtered"
    "decimal.handling.mode"       = "double"
    "_aiven.restart.on.failure"   = "true"
    "heartbeat.interval.ms"       = 30000
    "heartbeat.action.query"      = "INSERT INTO heartbeat (status) VALUES (1)"
  }
  depends_on = [aiven_service_integration.i1]
}



#### Open search sync

resource "aiven_kafka_topic" "kafka-topic" {
  project      = aiven_kafka.demo-kafka.project
  service_name = aiven_kafka.demo-kafka.service_name
  topic_name   = var.kafka_topic_name
  partitions   = 3
  replication  = 2
}

resource "aiven_opensearch" "os" {
  project                 = var.project_name
  service_name            = "aiven-opensearch" 
  cloud_name              = "google-europe-north1"
  plan                    = "startup-4"
  maintenance_window_dow  = "sunday"
  maintenance_window_time = "10:00:00"
}

resource "aiven_kafka_connector" "kafka-os-connector" {
  project        = aiven_kafka.demo-kafka.project
  service_name   = aiven_kafka.demo-kafka.service_name
  connector_name = var.kafka_connector_name

  config = {
    "topics"                         = aiven_kafka_topic.kafka-topic.topic_name
    "topic.prefix"                   = "prefix" 
    "connector.class"                = "io.aiven.kafka.connect.opensearch.OpensearchSinkConnector"
    "type.name"                      = "os-connector"
    "name"                           = var.kafka_connector_name
    "connection.url"                 = "https://${aiven_opensearch.os.service_host}:${aiven_opensearch.os.service_port}"
    "connection.username"            = aiven_opensearch.os.service_username
    "connection.password"            = aiven_opensearch.os.service_password
    "key.converter"                  = "org.apache.kafka.connect.storage.StringConverter"
    "value.converter"                = "org.apache.kafka.connect.json.JsonConverter"
    "tasks.max"                      = 1
    "schema.ignore"                  = true
    "value.converter.schemas.enable" = false
  }
}
