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

resource "aws_iam_policy_attachment" "dynamodb_policy" {
    name = "dynamodb-policy-attachment"
    users = ["${aws_iam_user.vault_user.name}"]
    policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# DO NOT REFORMAT THIS RESOURCE
# The policy JSON can not have any leading spaces, or the build will fail
resource "aws_iam_user_policy" "test_policy" {
    name = "${var.prefix}-s3-policy"
    user = "${aws_iam_user.vault_user.name}"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "s3:*",
            "Effect": "Allow",
            "Resource": [
                "${data.terraform_remote_state.storage.vault_bucket_arn}",
                "${data.terraform_remote_state.storage.vault_bucket_arn}/*"
            ]
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
        table_name = "${var.prefix}-ha-table"
        api_address = "https://${var.sub_domain}.${var.root_domain}"
    }
}

# data "template_file" "user_data" {
#     template = "${file("userdata.sh")}"

#     vars {
#         aws_access_key = "${aws_iam_access_key.vault_user.id}"
#         aws_secret_key = "${aws_iam_access_key.vault_user.secret}"
#         table_name = "${var.prefix}-server-table"
#         bucket_region = "${var.aws_region}"
#         api_address = "https://${var.sub_domain}.${var.root_domain}"
#     }
# }

data "aws_ami" "server_ami" {
    most_recent = true
    owners = ["self"]
    filter {
        name = "tag:Name"
        values = ["${var.server_tag}"]
    }
}

resource "aws_launch_configuration" "vault" {
    image_id = "${data.aws_ami.server_ami.id}"
    instance_type = "t2.micro"
    security_groups = ["${data.terraform_remote_state.security_groups.server_id}"]
    key_name = "${var.aws_key_pair_name}"

    user_data = "${data.template_file.user_data.rendered}"

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "group" {
    launch_configuration = "${aws_launch_configuration.vault.id}"
    availability_zones = ["${data.aws_availability_zones.all.names}"]
    vpc_zone_identifier = [
        "${data.terraform_remote_state.vpc.private_subnet_1_id}",
        "${data.terraform_remote_state.vpc.private_subnet_2_id}"
        ]

    min_size = "${var.instances}"
    max_size = "${var.instances}"

    tag {
        key = "Name"
        value = "${var.prefix}-private-server"
        propagate_at_launch = true
    }
}

resource "aws_alb_target_group" "server" {
    name = "${var.prefix}-server"
    port = 8200
    protocol = "HTTP"
    vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"
}

resource "aws_autoscaling_attachment" "group" {
    autoscaling_group_name = "${aws_autoscaling_group.group.id}"
    alb_target_group_arn = "${aws_alb_target_group.server.arn}"
}
