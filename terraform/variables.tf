variable "ami" {
  # The default is Debian 8.7 Jessie AMI in the eu-central-1 region.
  # https://wiki.debian.org/Cloud/AmazonEC2Image/Jessie
  default = "ami-5900cc36"
}

variable "control_root_volume_size" {
  default = 25
}

variable "instance_type" {
  default = "m4.large"
}

variable "nodes" {
  default = 5
}

variable "node_root_volume_size" {
  default = 25
}

variable "region" {
  default = "eu-central-1"
}

variable "run_id" {}

variable "vpc_id" {
  default = "vpc-03ca2768"
}
