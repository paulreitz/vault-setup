terraform {
    backend = "s3" {}
}

provider "aws" {
    region = "${var.aws_region}"
}

resource "aws_s3_bucket" "vault" {
    bucket = "${var.vault_bucket}"
}