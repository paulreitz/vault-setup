config {
    terraform_version = "0.10.2"
    deep_check = false

    ignore_rule = {
        aws_instance_not_specified_iam_profile = true
    }
}