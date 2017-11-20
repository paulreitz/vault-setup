output "server_target_group" {
    value = "${aws_alb_target_group.server.arn}"
}