resource "aws_sns_topic" "this" {
  name         = var.topic_name
  display_name = var.display_name
  
  kms_master_key_id = var.kms_key_id # Optional KMS encryption
  
  tags = merge(
    var.tags,
    {
      Name        = var.topic_name
      Environment = var.environment
    }
  )
}

# Initial policy that allows the account to manage the topic
# This avoids the circular dependency and can be updated later
resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.this.arn
  
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
        Resource  = aws_sns_topic.this.arn
        Condition = {
          StringEquals = {
            "aws:SourceOwner" = data.aws_caller_identity.current.account_id
          }
        }
      },
      # This statement allows S3 in general to publish to the topic
      # Without specific bucket restrictions initially
      {
        Sid       = "AllowS3ToPublish"
        Effect    = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.this.arn
      }
    ]
  })
}

# Optional: Create subscriptions for notifications
resource "aws_sns_topic_subscription" "email" {
  count     = length(var.email_subscriptions)
  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = var.email_subscriptions[count.index]
}

# Lambda subscription
resource "aws_sns_topic_subscription" "lambda" {
  count     = var.lambda_function_arn != "" ? 1 : 0
  topic_arn = aws_sns_topic.this.arn
  protocol  = "lambda"
  endpoint  = var.lambda_function_arn
}

# Lambda permission to allow SNS to invoke it
resource "aws_lambda_permission" "sns" {
  count         = var.lambda_function_arn != "" ? 1 : 0
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name != "" ? var.lambda_function_name : var.lambda_function_arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.this.arn
}

data "aws_caller_identity" "current" {}