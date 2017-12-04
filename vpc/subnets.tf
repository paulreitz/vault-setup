resource "aws_subnet" "public" {
    vpc_id = "${aws_vpc.vpc.id}"
    cidr_block = "10.0.0.0/24"
    availability_zone = "${var.availability_zone_1}"
    map_public_ip_on_launch = true
    tags {
        Name = "${var.prefix}-public-subnet"
    }
}

# `map_public_ip_on_launch` should not be included in the private subnets if you intend to use Vault solely for a secret store. 
# This needs to be included if you intend to use any backends that use an external API, such as AWS or Google Cloud.
# The security group already restricts access to instances in this subnet.
# NOTE: This could easily be fixed with a NAT gateway as well, but I'm cheap :P
resource "aws_subnet" "private_1" {
    vpc_id = "${aws_vpc.vpc.id}"
    cidr_block = "10.0.1.0/24"
    availability_zone = "${var.availability_zone_2}"
    map_public_ip_on_launch = true
    tags {
        Name = "${var.prefix}-private-subnet-1"
    }
}

resource "aws_subnet" "private_2" {
    vpc_id = "${aws_vpc.vpc.id}"
    cidr_block = "10.0.2.0/24"
    availability_zone = "${var.availability_zone_3}"
    map_public_ip_on_launch = true
    tags {
        Name = "${var.prefix}-private-subnet-2"
    }
}

resource "aws_route_table" "public" {
    vpc_id = "${aws_vpc.vpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.gateway.id}"
    }
    tags {
        Name = "${var.prefix}-public-route-table"
    }
}

resource "aws_route_table_association" "public" {
    subnet_id = "${aws_subnet.public.id}"
    route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table" "private" {
    vpc_id = "${aws_vpc.vpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.gateway.id}"
    }
    tags {
        Name = "${var.prefix}-private-route-table"
    }
}

resource "aws_route_table_association" "private-1" {
    subnet_id = "${aws_subnet.private_1.id}"
    route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "private-2" {
    subnet_id = "${aws_subnet.private_2.id}"
    route_table_id = "${aws_route_table.private.id}"
}

resource "aws_main_route_table_association" "private" {
    vpc_id = "${aws_vpc.vpc.id}"
    route_table_id = "${aws_route_table.private.id}"
}