output "load_balancer_id" {
    value = "${aws_security_group.load_balancer.id}"
}

output "jumpbox_id" {
    value = "${aws_security_group.jumpbox.id}"
}

output "server_id" {
    value = "${aws_security_group.server.id}"
}

output "ui_id" {
    value = "${aws_security_group.ui.id}"
}