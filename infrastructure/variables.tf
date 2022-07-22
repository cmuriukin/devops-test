variable "region" {}
variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "number_of_instances" {
  description = "Number of instances to create and attach to ELB"
  type        = string
  default     = 1
}

variable "public_key" {
  default = "tests.pub"
}
# Defining Private Key
variable "private_key" {
  default = "tests.pem"
}
# Definign Key Name for connection
variable "key_name" {
  default = "tests"
  description = "Name of AWS key pair"
}
# Defining CIDR Block for VPC
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}
# Defining CIDR Block for Subnet
variable "subnet_cidr" {
  default = "10.0.1.0/24"
}
# Defining CIDR Block for 2d Subnet
variable "subnet1_cidr" {
  default = "10.0.2.0/24"
}