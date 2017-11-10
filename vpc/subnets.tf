resource "aws_subnet" "public" {
    vpc_id = "${aws_vpc.vpc.id}"
    cidr_block = "10.0.0.0/24"
    availability_zone = "${var.availability_zone}"
    map_public_ip_on_launch = true
    tags {
        Name = "${var.prefix}-public-subnet"
    }
}

resource "aws_subnet" "private" {
    vpc_id = "${aws_vpc.vpc.id}"
    cidr_block = "10.0.1.0/24"
    availability_zone = "${var.availability_zone}"
    tags {
        Name = "${var.prefix}-private-subnet"
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
    subnet_id = "${aws_subnet.private.id}"
    route_table_id = "${aws_route_table.private.id}"
}

resource "aws_main_route_table_association" "private" {
    vpc_id = "${aws_vpc.vpc.id}"
    route_table_id = "${aws_route_table.private.id}"
}