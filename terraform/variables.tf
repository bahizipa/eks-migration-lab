variable "project" {
  type    = string
  default = "notes-lab"
}

variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "cluster_version" {
  type    = string
  default = "1.31"
}

variable "node_instance_type" {
  type    = string
  default = "t3.small"
}

variable "node_desired" {
  type    = number
  default = 2
}

variable "db_name" {
  type    = string
  default = "notes"
}

variable "db_user" {
  type    = string
  default = "notes"
}
