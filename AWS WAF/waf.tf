resource "aws_waf_rule" "Global_WAF_Rule_IPSet_Blacklist" {
  name        = "${var.GlobalWAFRuleIPSetBlacklistName}"
  metric_name = "${var.GlobalWAFRuleIPSetBlacklistMetricName}"
  predicates {
    data_id = "${aws_waf_ipset.Global_WAF_IPSet.id}"
    negated = false
    type    = "IPMatch"
  }
}
resource "aws_waf_rule" "Global_WAF_SQLi_MatchSet" {
  name        = "${var.GlobalWAFRuleSQLiMatchSetName}"
  metric_name = "${var.GlobalWAFRuleSQLiMatchSeMetricName}"
  predicates{
    data_id = "${aws_waf_sql_injection_match_set.Global_WAF_SQLi_MatchSet.id}"
    negated = false
    type = "SqlInjectionMatch"
  }
}
resource "aws_waf_rule" "Global_WAF_Rule_XSS_MatchSet" {
  name        = "${var.GlobalWAFRuleXSSMatchSetName}"
  metric_name = "${var.GlobalWAFRuleSXSSMatchSeMetricName}"
  predicates {
    data_id = "${aws_waf_xss_match_set.Global_WAF_XSS_MatchSet.id}"
    negated = false
    type = "XssMatch"
  }
}
resource "aws_waf_rule" "Global_WAF_Rule_SizeConstraint_MatchSet" {
  name        = "${var.GlobalWAFSizeConstraintMatchSetName}"
  metric_name = "${var.GlobalWAFRuleSConstraintSizeMatchSeMetricName}"
  predicates {
    data_id = "${aws_waf_size_constraint_set.Global_WAF_SizeConstraint_MatchSet.id}"
    negated = false
    type = "SizeConstraint"
  }
}
resource "aws_waf_web_acl" "Global_WAF_Blacklist_WACL" {
  name        = "${var.GlobalWAFWebACLName}"
  metric_name = "${var.GlobalWAFWebACLMetricName}"
  logging_configuration {
    log_destination = "${aws_kinesis_firehose_delivery_stream.Global_WAF_KDF_Delivery_Stream.arn}"
  }
  default_action {
    type = "ALLOW"
  }
  rules {
    action {
      type = "BLOCK"
    }
    priority = 1
    rule_id  = "${aws_waf_rule.Global_WAF_Rule_IPSet_Blacklist.id}"
    type     = "REGULAR"
  }
  rules {
    action {
      type = "BLOCK"
    }
    priority = 2
    rule_id  = "${aws_waf_rule.Global_WAF_SQLi_MatchSet.id}"
    type     = "REGULAR"
  }
  rules {
    action {
      type = "BLOCK"
    }
    priority = 3
    rule_id  = "${aws_waf_rule.Global_WAF_Rule_XSS_MatchSet.id}"
    type     = "REGULAR"
  }
   rules {
    action {
      type = "BLOCK"
    }
    priority = 4
    rule_id  = "${aws_waf_rule.Global_WAF_Rule_SizeConstraint_MatchSet.id}"
    type     = "REGULAR"
  }
}
resource "aws_kinesis_firehose_delivery_stream" "Global_WAF_KDF_Delivery_Stream" {
  name        = "aws-waf-logs-${var.WAFLogsKinesisFirehoseStreamNamePrefix}"
  destination = "extended_s3"
  extended_s3_configuration {
    role_arn   = "${aws_iam_role.Global_WAF_KDF_Delivery_Stream_Role.arn}"
    bucket_arn = "${aws_s3_bucket.Global_WAF_Logs_Bucket.arn}"
  }
}
resource "aws_s3_bucket" "Global_WAF_Logs_Bucket" {
  bucket = "${var.WAFLogsS3BucketName}"
  acl    = "private"
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
  }
}
resource "aws_iam_role" "Global_WAF_KDF_Delivery_Stream_Role" {
  name = "${var.WAFLogsKinesisFirehoseStreamRoleName}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
resource "aws_iam_policy" "Global_WAF_KDF_DeliverToS3_Policy" {
  name        = "${var.WAFLogsKinesisFirehoseStreamRolePolicyName}"
  path        = "/"
  description = "${var.WAFLogsKinesisFirehoseStreamRolePolicyDescription}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1555544710122",
      "Action": [
        "s3:AbortMultipartUpload",        
        "s3:GetBucketLocation",        
        "s3:GetObject",        
        "s3:ListBucket",        
        "s3:ListBucketMultipartUploads",        
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.Global_WAF_Logs_Bucket.arn}",
        "${aws_s3_bucket.Global_WAF_Logs_Bucket.arn}/*"
      ]
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "Global_WAF_KDF_DeliverToS3_Policy_Attachment" {
  role       = "${aws_iam_role.Global_WAF_KDF_Delivery_Stream_Role.name}"
  policy_arn = "${aws_iam_policy.Global_WAF_KDF_DeliverToS3_Policy.arn}"
}