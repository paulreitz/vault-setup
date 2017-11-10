terraform {
    backend = "s3" {}
}

provider "aws" {
    region = "${var.aws_region}"
}

data "aws_availability_zones" "all" {}

resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    tags {
        Name = "${var.prefix}-vpc"
    }
}

resource "aws_internet_gateway" "gateway" {
    vpc_id = "${aws_vpc.vpc.id}"
    tags {
        Name = "${var.prefix}-internet-gateway"
    }
}

resource "aws_vpc_endpoint" "s3" {
    vpc_id = "${aws_vpc.vpc.id}"
    route_table_ids = ["${aws_route_table.public.id}","${aws_route_table.private.id}"]
    service_name = "com.amazonaws.${var.aws_region}.s3"
}

resource "aws_vpc_dhcp_options" "vpc" {
    domain_name = "ec2.internal"
    domain_name_servers = ["AmazonProvidedDNS"]
    tags {
        Name = "DHCP-${aws_vpc.vpc.id}"
    }
}

resource "aws_vpc_dhcp_options_association" "vpc" {
    vpc_id = "${aws_vpc.vpc.id}"
    dhcp_options_id = "${aws_vpc_dhcp_options.vpc.id}"
}