resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.bucket_id

  topic {
    topic_arn     = var.topic_arn
    events        = var.events
    filter_prefix = var.filter_prefix
    filter_suffix = var.filter_suffix
  }
}

# Optionally update the SNS topic policy to restrict to this specific bucket
resource "aws_sns_topic_policy" "update_topic_policy" {
  count = var.update_sns_policy ? 1 : 0
  
  arn    = var.topic_arn
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${var.topic_name}-policy"
    Statement = [
      {
        Sid       = "DefaultPolicy"
        Effect    = "Allow"
        Principal = {
          AWS = "*"
        }
        Action    = [
          "sns:GetTopicAttributes",
          "sns:SetTopicAttributes",
          "sns:AddPermission",
          "sns:RemovePermission",
          "sns:DeleteTopic",
          "sns:Subscribe",
          "sns:ListSubscriptionsByTopic",
          "sns:Publish"
        ]
        Resource  = var.topic_arn
        Condition = {
          StringEquals = {
            "aws:SourceOwner" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid       = "AllowS3ToPublish"
        Effect    = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action    = "sns:Publish"
        Resource  = var.topic_arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:s3:::${var.bucket_id}"
          }
        }
      }
    ]
  })
}

data "aws_caller_identity" "current" {}