terraform {
    backend "s3" {}
}

provider "aws" {
    region = "${var.aws_region}"
}

data "terraform_remote_state" "vpc" {
    backend = "s3"
    config {
        bucket = "${var.tfstate_bucket_name}"
        key = "${var.vpc_state_key}"
        region = "${var.aws_region}"
    }
}

data "terraform_remote_state" "security_groups" {
    backend = "s3"
    config {
        bucket = "${var.tfstate_bucket_name}"
        key = "${var.security_groups_state_key}"
        region = "${var.aws_region}"
    }
}

data "terraform_remote_state" "ui" {
    backend = "s3"
    config {
        bucket = "${var.tfstate_bucket_name}"
        key = "${var.ui_state_key}"
        region = "${var.aws_region}"
    }
}

data "terraform_remote_state" "server" {
    backend = "s3"
    config {
        bucket = "${var.tfstate_bucket_name}"
        key = "${var.server_state_key}"
        region = "${var.aws_region}"
    }
}

data "aws_acm_certificate" "cert" {
    domain = "*.${root_domain}"
    statuses = ["ISSUED"]
}

resource "aws_alb" "vault_load_balancer" {
    name = "${var.prefix}-load-balancer"
    subnets = [
        "${data.terraform_remote_state.vpc.public_subnet_id}",
        "${data.terraform_remote_state.vpc.private_subnet_1_id}",
        "${data.terraform_remote_state.vpc.private_subnet_2_id}"
    ]
    security_groups = "${data.terraform_remote_state.security_groups.load_balancer_id}"
}

resource "aws_route53_record" "subdomain" {
    zone_id = "${var.dns_zone_id}"
    name = "${var.sub_domain}.${var.root_domain}"
    type = "CNAME"
    ttl = "300"
    records = ["${aws_alb.vault_load_balancer.dns_name}"]
}

resource "aws_alb_listener" "vaut_listener" {
    load_balancer_arn = "${aws_alb.vault_load_balancer.arn}"
    port = 443
    protocol = "HTTPS"
    certificate_arn = "${data.aws_acm_certificate.cert.arn}"

    default_action {
        target_group_arn = "${data.terraform_remote_state.ui.ui_target_group}"
        type = "forward"
    }
}

resource "aws_alb_listener_rule" "vault_server" {
    listener_arn = "${aws_alb_listener.vaut_listener.arn}"
    priority = 100

    action {
        type = "forward"
        target_group_arn = "${data.terraform_remote_state.server.server_target_group}"
    }

    condition {
        field = "path-pattern"
        values = ["/v1/*"]
    }
}