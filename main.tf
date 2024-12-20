######################
/* S3 Buckets */
######################
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  tags = {
    name = var.bucket_name
  }
}

######################
/* S3 Bucket Config */
######################
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning
  }
}

resource "aws_s3_bucket_object_lock_configuration" "this" {
  for_each = var.object_lock

  bucket = aws_s3_bucket.this.id

  rule {
    default_retention {
      mode  = each.value.mode
      days  = try(each.value.day, null)
      years = try(each.value.years, null)
    }
  }

  depends_on = [ aws_s3_bucket_versioning.this ]
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.object_ownership
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cmk" {
  bucket = aws_s3_bucket.this.id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      kms_master_key_id = var.cmk_id
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {

  bucket = aws_s3_bucket.this.id

  rule {
    id = "abort_incomplete_multipart_upload"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
    status = "Enabled"
  }

  dynamic "rule" {
    for_each = var.rule

    content {
      id = rule.value.rule_id

      dynamic "expiration" {
        for_each = try(rule.value.expiration, {})

        content {
          days = expiration.value.days
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = try(rule.value.noncurrent_version_expiration, {})

        content {
          noncurrent_days = noncurrent_version_expiration.value.noncurrent_days
        }
      }

      dynamic "filter" {
        for_each = try(rule.value.filter, {})

        content {
          prefix = filter.value.prefix
        }
      }

      dynamic "transition" {
        for_each = try(rule.value.transition, {})

        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      status = "Enabled"
    }
  }
}

###########################
/* S3 Policy Attachments */
###########################

data "aws_iam_policy_document" "s3_ssl" {
  statement {
    sid       = "AllowSSLRequestsOnly"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = ["${aws_s3_bucket.this.arn}", "${aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = ["1.2"]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.combined.json

  depends_on = [aws_s3_bucket_public_access_block.this]
}

data "aws_iam_policy_document" "combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.s3_ssl.json,
    var.add_policy
  ]
}

resource "aws_s3_object" "this" {
  for_each = var.object

  key                = each.value.key
  bucket             = aws_s3_bucket.this.id
  source             = try(each.value.source, null)
  bucket_key_enabled = true
}