resource "aiven_pg" "demo-pg" {
  project      = var.avn_project
  service_name = "demo-postgres"
  cloud_name   = "google-europe-north1"
  plan         = "business-4"
}


resource "aiven_kafka" "franz" {
  project                 = var.avn_project
  service_name            = var.kafka_name
  cloud_name              = "google-europe-west1"
  plan                    = "business-4"
  maintenance_window_dow  = "monday"
  maintenance_window_time = "10:00:00"

  kafka_user_config {
    // Enables Kafka Connectors
    kafka_connect   = true
    kafka_version   = "3.8"
    schema_registry = true

    kafka {
      group_max_session_timeout_ms = 70000
      log_retention_bytes          = 1000000000
      auto_create_topics_enable    = true

    }
  }
}

resource "aiven_kafka_topic" "kafka-topic" {
  project      = aiven_kafka.franz.project
  service_name = aiven_kafka.franz.service_name
  topic_name   = var.kafka_topic_name
  partitions   = 3
  replication  = 2
}

resource "aiven_opensearch" "os" {
  project                 = var.avn_project
  service_name            = var.os_name
  cloud_name              = "google-europe-west1"
  plan                    = "startup-4"
  maintenance_window_dow  = "monday"
  maintenance_window_time = "10:00:00"
}

resource "aiven_kafka_connector" "kafka-os-connector" {
  project        = aiven_kafka.franz.project
  service_name   = aiven_kafka.franz.service_name
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

resource "aiven_kafka_connector" "kafka-pg-connector" {
  project        = aiven_kafka.franz.project
  service_name   = aiven_kafka.franz.service_name
  connector_name = "kafka-pg-connector"

  config = {
    "name"                        = "kafka-pg-connector",
    "topics"                      = aiven_kafka_topic.kafka-topic.topic_name
    "topic.prefix"                = "prefix",
    "connector.class"             = "io.debezium.connector.postgresql.PostgresConnector",
    "database.hostname"           = sensitive(aiven_pg.demo-pg.service_host)
    "database.port"               = sensitive(aiven_pg.demo-pg.service_port)
    "database.password"           = sensitive(aiven_pg.demo-pg.service_password)
    "database.user"               = sensitive(aiven_pg.demo-pg.service_username)
    "database.dbname"             = "defaultdb"
    "database.ssl.mode"           = "require",
    "database.server.id"          = "12345",
    "plugin.name"                 = "pgoutput",
    "publication.name"            = "dbz_publication",
    "publication.autocreate.mode" = "all_tables",
    "table.include.list"          = "defaultdb.users",
    "tasks.max"                   = "1",
    "include.schema.changes"      = "true"
  }
}
