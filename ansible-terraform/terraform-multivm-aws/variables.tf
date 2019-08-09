variable "region" {
  description = "The AWS region to create instance in."
  default = "us-east-2"
}
variable "machine_type" {
  description = "type of instance to fire up"
  default = "t2.micro" 
}
variable "zone" {
  description = "zone you wish to create the instance in"
  default = "us-west1-a" 
}
variable "cluster_count" {
  description = "number of instances to boot up"
  default = "3"
}
variable "PRIVATE_KEY" {
  description = "location of private key"
  default = "~/.ssh/id_rsa"
}
variable "PUBLIC_KEY" {
  description = "location of public key"
  default = "~/.ssh/id_rsa.pub"
}
variable "BITBUCKET_KEY" {
  description = "location of bickbucket private key"
  default = "~/.ssh/id_rsa"
}
variable "USER" {
  description = "user to set up instance"
  default = "centos"
}
