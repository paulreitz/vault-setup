terraform {
    backend "s3" {}
}

provider "aws" {
    region = "${var.aws_region}"
}

data "terraform_remote_state" "vpc" {
    backend = "s3"
    config = {
        bucket = "${var.tfstate_bucket_name}"
        key = "${var.vpc_state_key}"
        region = "${var.aws_region}"
    }
}

data "terraform_remote_state" "security_groups" {
    backend = "s3"
    config = {
        bucket = "${var.tfstate_bucket_name}"
        key = "${var.security_groups_state_key}"
        region = "${var.aws_region}"
    }
}

data "aws_ami" "ubuntu" {
    most_recent = true
    filter {
        name = "name"
        values = ["ubuntu/images/*ubuntu-xenial-16.04-amd64-server-*"]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
    filter {
        name = "root-device-type"
        values = ["ebs"]
    }
    owners = ["099720109477"]
}

resource "aws_instance" "jumpbox" {
    ami = "${data.aws_ami.ubuntu.id}"
    instance_type = "t2.micro"
    subnet_id = "${data.terraform_remote_state.vpc.public_subnet_id}"
    vpc_security_group_ids = ["${data.terraform_remote_state.security_groups.jumpbox_id}"]
    key_name = "${var.aws_key_pair_name}"
    tags {
        Name = "${var.prefix}-jumpbox"
    }
}

resource "aws_eip" "eip" {
    instance = "${aws_instance.jumpbox.id}"
    vpc = true
}

resource "aws_eip_association" "eip" {
    instance_id = "${aws_instance.jumpbox.id}"
    allocation_id = "${aws_eip.eip.id}"
}