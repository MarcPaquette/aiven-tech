variable "kafka_name" {}
variable "kafka_connector_name" {}
variable "kafka_topic_name" {}
variable "os_name" {}

variable "aiven_api_token" { 
// Should replace aiven_token
description = "Aiven console API token"
type        = string
}

variable "project_name" {
// Should replace avn_project 
description = "Aiven console project name"
type        = string
}
