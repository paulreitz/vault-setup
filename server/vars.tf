variable "aws_region" {}
variable "tfstate_bucket_name" {}
variable "vpc_state_key" {}
variable "security_groups_state_key" {}
variable "storage_state_key" {}
variable "server_tag" {}
variable "prefix" {}
variable "vault_name" {}
variable "dns_zone_id" {}
variable "root_domain" {}
variable "server_subdomain" {}
variable "ssl_certificate" {}
variable "aws_key_pair_name" {}
variable "instances" {
    default = 1
}