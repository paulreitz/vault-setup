output "vpc_id" {
    value = "${aws_vpc.vpc.id}"
}

output "public_subnet_id" {
    value = "${aws_subnet.public.id}"
}

output "private_subnet_1_id" {
    value = "${aws_subnet.private_1.id}"
}

output "private_subnet_2_id" {
    value = "${aws_subnet.private_2.id}"
}