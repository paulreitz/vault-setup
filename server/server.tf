terraform {
    backend "s3" {}
}

provider "aws" {
    region = "${var.aws_region}"
}

data "aws_availability_zones" "all" {}

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

data  "terraform_remote_state" "storage" {
    backend = "s3"
    config {
        bucket = "${var.tfstate_bucket_name}"
        key = "${var.storage_state_key}"
        region = "${var.aws_region}"
    }
}

resource "aws_iam_user" "vault_user" {
    name = "${var.prefix}User"
}

resource "aws_iam_access_key" "vault_user" {
    user = "${aws_iam_user.vault_user.name}"
}

resource "aws_iam_user_policy" "test_policy" {
    name = "test-policy"
    user = "${aws_iam_user.vault_user.name}"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "s3:*",
            "Effect": "Allow",
            "Resource": "${data.terraform_remote_state.storage.vault_bucket_arn}"
        }
    ]
}
EOF
}

data "template_file" "user_data" {
    template = "${file("userdata.sh")}"

    vars {
        aws_access_key = "${aws_iam_access_key.vault_user.id}"
        aws_secret_key = "${aws_iam_access_key.vault_user.secret}"
        bucket_name = "${data.terraform_remote_state.storage.vault_bucket_name}"
        bucket_region = "${var.aws_region}"
    }
}

data "aws_ami" "server_ami" {
    most_recent = true
    owners = ["self"]
    filter {
        name = "tag:Name"
        values = ["${var.server_tag}"]
    }
}

resource "aws_launch_configuration" "vault" {
    image_id = "${aws_ami.server_ami.id}"
    instance_type = "t2.micro"
    security_groups = ["${data.terraform_remote_state.security_groups.server_id}"]
    key_name = "${var.aws_key_pair_name}"

    user_data = "${data.template_file.user_data.rendered}"

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_elb" "load_balancer" {
    name = "${var.prefix}-load-balancer"
    subnets = ["${data.terraform_remote_state.vpc.public_subnet_id}"]
    security_groups = ["${data.terraform_remote_state.security_groups.load_balancer_id}"]

    listener {
        lb_port = 443
        lp_protocol = "https"
        instance_port = 8200
        instance_protocol = "http"
        ssl_certificate_id = "${var.ssl_certificate}"
    }
}

resource "aws_autoscaling_group" "group" {
    launch_configuration = "${aws_launch_configuration.vault.id}"
    availability_zones = ["${data.aws_availability_zones.all.names}"]
    vpc_zone_identifier = ["${data.terraform_remote_state.vpc.private_subnet_id}"]

    min_size = "${var.instances}"
    max_size = "${var.instances}"

    tag {
        key = "Name"
        value = "vault-private-server"
        propagate_at_launch = true
    }
}

resource "aws_autoscaling_attachment" "attachment" {
    autoscaling_group_name = "${aws_autoscaling_group.group.id}"
    elb = "${aws_elb.load_balancer.id}"
}

resource "aws_route53_record" "subdomain" {
    zone_id = "${var.dns_zone_id}"
    name = "${var.server_subdomain}.${var.root_domain}"
    type = "CNAME"
    ttl = "300"
    records = ["${aws_elb.load_balancer.dns_name}"]
}