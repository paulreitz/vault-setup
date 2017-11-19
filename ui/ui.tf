terraform {
    backend "s3" {}
}

provider "aws" {
    region = "${var.aws_region}"
}

data "aws_availability_zones" "all" {}

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

data "template_file" "user_data" {
    template = "${file("userdata.sh")}"

    vars {
        vault_endpoint = "https://${var.sub_domain}.${var.root_domain}"
    }
}

data "aws_ami" "ui_ami" {
    most_recent = true
    owners = ["self"]
    filter {
        name = "tag:Name" 
        values = ["${var.ui_tag}"]
    }
}

resource "aws_launch_configuration" "ui" {
    image_id = "${data.aws_ami.ui_ami.id}"
    instance_type = "t2.micro"
    security_groups = ["${data.terraform_remote_state.security_groups.ui_id}"]
    key_name = "${var.aws_key_pair_name}"

    user_data = "${data.template_file.user_data.rendered}"
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "group" {
    launch_configuration = "${aws_launch_configuration.ui.id}"
    availability_zones = ["${data.aws_availability_zones.all.names}"]
    vpc_zone_identifier = ["${data.terraform_remote_state.vpc.public_subnet_id}"]

    min_size = "${var.instances}"
    max_size = "${var.instances}"

    tag {
        key = "Name" 
        value = "vault-ui-private-server"
        propagate_at_launch = true
    }
}

resource "aws_alb_target_group" "ui" {
    name = "${var.prefix}"
    port = 80
    protocol = "HTTP"
    vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"
}

resource "aws_autoscaling_attachment" "group" {
    autoscaling_group_name = "${aws_autoscaling_group.group.id}"
    alb_target_group_arn = "${aws_alb_target_group.ui.arn}"
}