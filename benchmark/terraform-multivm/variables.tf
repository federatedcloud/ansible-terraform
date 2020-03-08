variable "credentials" {
  description = "The google credentials" 
  default = "googCredentials.json"
}
variable "region" {
  description = "The GCE region to create instance in."
  default = "us-east1"
}
variable "project_id" {
  description = "name of your project"
  default = "jetstream-documentation" 
}
variable "machine_type" {
  description = "type of instance to fire up"
  default = "n1-standard-1" 
}
variable "zone" {
  description = "zone you wish to create the instance in"
  default = "us-east1-b" 
}
variable "disk_size" {
  description = "GB of memory used on disk"
  default = "10"
}
variable "disk_type" {
  description = "type of gcp disk (usually pd-standard or pd-ssd)"
  default = "pd-standard"
}
variable "image" {
  description = "image to boot up"
  default = "centos-cloud/centos-7" 
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
