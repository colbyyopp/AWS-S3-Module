output "s3_bucket" {
  value = {
    for k, v in aws_s3_bucket.this :
    k => v
  }
}

output "s3_object" {
  value = {
    for k, v in aws_s3_object.this :
    k => v
  }
}