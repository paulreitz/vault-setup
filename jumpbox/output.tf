output "jumpbox_ip" {
    value = "${aws_eip.eip.public_ip}"
}