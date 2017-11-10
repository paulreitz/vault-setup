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

resource "aws_security_group" "load_balancer" {
    name = "${var.prefix}-load-balancer-security-group"
    vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["${var.whitelist}"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "jumpbox" {
    name = "${var.prefix}-jumpbox-security-group"
    vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.whitelist}"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "server" {
    name = "${var.prefix}-server-security-group"
    vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }

    ingerss {
        from_port = 8200
        to_port = 8201
        protocol = "tcp"
        security_groups = ["${aws_security_group.load_balancer.id}"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "ui" {
    name = "${var.prefix}-ui-security-group"
    vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = ["${aws_security_group.load_balancer.id}"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}