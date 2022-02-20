# This is used for the Lambda name and CloudWatch Log group, which is automatically created by AWS
# but we can manage it via Terraform if we use the same name
locals {
  name = "trusted-advisor-refresh"
}

# IAM role
data "aws_iam_policy_document" "assume-role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "default" {
  # Allow the function to write logs
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["${aws_cloudwatch_log_group.default.arn}:*"]
  }

  # Support doesn't allow you to target individual resources, so we need to use *
  statement {
    effect = "Allow"
    actions = [
      "support:DescribeTrustedAdvisorChecks",
      "support:RefreshTrustedAdvisorCheck"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "default" {
  name   = local.name
  policy = data.aws_iam_policy_document.default.json
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.default.name
  policy_arn = aws_iam_policy.default.arn
}

resource "aws_iam_role" "default" {
  name               = "AWSTrustedAdvisorRefresh"
  assume_role_policy = data.aws_iam_policy_document.assume-role.json
}

# CloudWatch Log
resource "aws_cloudwatch_log_group" "default" {
  name              = "/aws/lambda/${local.name}"
  retention_in_days = 30
  tags              = var.tags
}

# EventBridge (previously known as CloudWatch) scheduled event
resource "aws_cloudwatch_event_rule" "default" {
  name                = "run-${local.name}-hourly"
  description         = "Scheduled event for ${local.name}"
  schedule_expression = "rate(60 minutes)"
}

resource "aws_cloudwatch_event_target" "default" {
  rule = aws_cloudwatch_event_rule.default.name
  arn  = aws_lambda_function.default.arn
}

# Lambda function
## ZIP up the function
data "archive_file" "function" {
  type        = "zip"
  output_path = "${path.module}/function.zip"

  source {
    content  = file("${path.module}/function/index.js")
    filename = "index.js"
  }

  source {
    content  = file("${path.module}/function/utilities.js")
    filename = "utilities.js"
  }

  source {
    content  = file("${path.module}/function/package.json")
    filename = "package.json"
  }
}

## Give CloudWatch permission to run it (via a Scheduled Event)
resource "aws_lambda_permission" "default" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.default.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.default.arn
}

## Create the Lambda function
resource "aws_lambda_function" "default" {
  filename         = data.archive_file.function.output_path
  function_name    = local.name
  handler          = "index.handler"
  role             = aws_iam_role.default.arn
  runtime          = "nodejs12.x"
  source_code_hash = data.archive_file.function.output_base64sha256
  timeout          = "60"

  depends_on = [
    data.archive_file.function,
    aws_cloudwatch_log_group.default
  ]
}