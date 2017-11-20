resource "aws_subnet" "public" {
    vpc_id = "${aws_vpc.vpc.id}"
    cidr_block = "10.0.0.0/24"
    availability_zone = "${var.availability_zone_1}"
    map_public_ip_on_launch = true
    tags {
        Name = "${var.prefix}-public-subnet"
    }
}

resource "aws_subnet" "private_1" {
    vpc_id = "${aws_vpc.vpc.id}"
    cidr_block = "10.0.1.0/24"
    availability_zone = "${var.availability_zone_1}"
    tags {
        Name = "${var.prefix}-private-subnet-1"
    }
}

resource "aws_subnet" "private_2" {
    vpc_id = "${aws_vpc.vpc.id}"
    cidr_block = "10.0.2.0/24"
    availability_zone = "${var.availability_zone_2}"
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
    tags {
        Name = "${var.prefix}-private-route-table"
    }
}

resource "aws_route_table_association" "private" {
    subnet_id = "${aws_subnet.private_1.id}"
    route_table_id = "${aws_route_table.private.id}"
}

resource "aws_main_route_table_association" "private" {
    vpc_id = "${aws_vpc.vpc.id}"
    route_table_id = "${aws_route_table.private.id}"
}