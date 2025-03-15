variable "kafka_name" {}
variable "kafka_connector_name" {}
variable "kafka_topic_name" {}

variable "aiven_api_token" { 
description = "Aiven console API token"
type        = string
}

variable "project_name" {
description = "Aiven console project name"
type        = string
}
