## AWS S3 Module 
This Terraform module is designed to streamline the creation and management of AWS S3 buckets and works in tandem with our IAM policy module for the necessary policies for access and security. It automates the provisioning of S3 buckets with best practices in mind, ensuring they are efficiently configured for cost, performance, and security.

## Some Important Features
Dynamic block has been implemented for the lifecycle configuration so multiple rules can be created. Object ownership can also be changed in the root module declaration depending on if the object writer or bucket owner having ownership of written objects is preferred.

## Standard Name - Bucket
```
${var.env}-test-${data.aws_caller_identity.current.account_id}
```

## Example of Module in Use
An important note for this to work correctly is to be sure that the local key names for the S3 buckets and the policies match. You can see this in the locals block of this example:
```
module "s3" {
  source = "api.env0.com/env0identifierhere/aws-s3/ado"
  version = "0.1.0"

  for_each = local.s3_bucket

  bucket_name      = each.value.bucket
  rule             = try(each.value.rule, {})
  add_policy       = try(module.s3_policy[each.key].policy.json, "")
  cmk_id           = module.kms[each.value.keyid].key.arn
  object           = try(each.value.object, {})
  object_ownership = "BucketOwnerEnforced"
  object_lock      = try(each.value.object_lock, {})
  versioning       = try(each.value.versioning, "Disabled")
}

module "s3_policy" {
  source  = "api.env0.com/env0identifierhere/aws-policy/ado"
  version = "1.0.0"

  for_each = local.s3_policies

  policy = each.value
}

data "aws_caller_identity" "current" {
  
}

locals {
  s3_bucket = {
    bucket_a = {
      bucket            = "${var.env}-testing-${data.aws_caller_identity.current.account_id}"
      kms_master_key_id = "test"
      rule = [{
        rule_id = "test1"
        expiration = [{
            days = 90
        }]
      }]
    }
    bucket_b = {
      bucket            = "${var.env}-testing2-${data.aws_caller_identity.current.account_id}"
      kms_master_key_id = "test"
      versioning  = "Enabled"
      object_lock = {
        default = {
          mode  = "GOVERNANCE"
          years = 7
        }
      }
      object = {
          test = { key = "test1/test2/" }
      }
      rule = {
        test2 = {
          rule_id = "test2"
          transition {
            days          = 30
            storage_class = "STANDARD_IA"
          }
        }
        noncurrent_expire_30day = {
          rule_id                       = "noncurrent_expire_30day"
          noncurrent_version_expiration = [{ noncurrent_days = 35 }]
        }
      }
    }
  }

  s3_policies = {
    bucket_a = {
      test = {
        sid = "test3"
        actions = ["s3:*"]
        resources = ["${module.s3["bucket_a"].s3_bucket.arn}", "${module.s3["bucket_a"].s3_bucket.arn}/*"]
        principals = [{
          type        = "AWS"
          identifiers = ["arn:aws:iam::4123412341:role/aws-reserved/sso.amazonaws.com/us-east-2/AWSReservedSSO_Cloud_Engineer_Playground"] #["arn:aws:iam:${data.aws_caller_identity.current.account_id}:root"]
        }]
      }
      test2 = {
        sid        = "test2"
        actions    = ["s3:ListBucket","s3:GetBucketLocation"]
        resources  = ["${module.s3["bucket_a"].s3_bucket.arn}"]
        principals = [{
          type        = "AWS"
          identifiers = ["arn:aws:iam::412341234123:role/aws-reserved/sso.amazonaws.com/us-east-2/AWSReservedSSO_Cloud_Engineer_Playground"] #["arn:aws:iam:${data.aws_caller_identity.current.account_id}:root"]
        }]
        condition = [{
          test     = "NumericLessThan"
          variable = "s3:TlsVersion"
          values   = ["1.2"]
        }]
      }
    }
    bucket_b = {
      test3 = {
        sid = "test3"
        actions = ["s3:*"]
        resources = ["${module.s3["bucket_b"].s3_bucket.arn}", "${module.s3["bucket_b"].s3_bucket.arn}/*"]
        principals = [{
          type        = "AWS"
          identifiers = ["arn:aws:iam::41234123412:role/aws-reserved/sso.amazonaws.com/us-east-2/AWSReservedSSO_Cloud_Engineer_Playground"] #["arn:aws:iam:${data.aws_caller_identity.current.account_id}:root"]
        }]
      }
    }
  }
}
```

### Note  
Bucket B above showcases additional optinal features available in the module. The try statements help make it optional.