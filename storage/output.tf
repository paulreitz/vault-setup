output "vault_bucket_arn" {
    value = "${aws_s3_bucket.vault.arn}"
}

output "vault_bucket_name" {
    value = "${aws_s3_bucket.vault.bucket}"
}