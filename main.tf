# -----------------------------------------------------------------------------
# EventBridge Custom Bus
# -----------------------------------------------------------------------------
module "eventbridge_bus" {
  source = "./modules/eventbridge-bus"

  name = "ops-main-cust-bus"
  tags = var.tags
}

# -----------------------------------------------------------------------------
# CloudWatch Logs Target
# -----------------------------------------------------------------------------
module "cloudwatch_log_group" {
  source = "./modules/cloudwatch-log-group"

  name              = "/eventbridge/ops-main-cust-bus/monitoring"
  retention_in_days = 14
  tags              = var.tags
}

# IAM Role for CloudWatch Logs
resource "aws_iam_role" "eventbridge_logs_role" {
  name = "eventbridge-logs-role"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "eventbridge_logs_policy" {
  name        = "eventbridge-logs-policy"
  description = "Allow EventBridge to write to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "${module.cloudwatch_log_group.arn}:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge_logs_attach" {
  role       = aws_iam_role.eventbridge_logs_role.name
  policy_arn = aws_iam_policy.eventbridge_logs_policy.arn
}

# -----------------------------------------------------------------------------
# SQS Target
# -----------------------------------------------------------------------------
module "sqs_queue" {
  source = "./modules/sqs-queue"

  name = "update-omnibus"
  dlq_config = {
    enabled           = true
    name              = "update-omnibus-dlq"
    max_receive_count = 5
  }
  tags = var.tags
}

# IAM Role for SQS
resource "aws_iam_role" "eventbridge_sqs_role" {
  name = "eventbridge-sqs-role"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "eventbridge_sqs_policy" {
  name        = "eventbridge-sqs-policy"
  description = "Allow EventBridge to send messages to SQS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "sqs:SendMessage"
        Effect   = "Allow"
        Resource = module.sqs_queue.queue_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge_sqs_attach" {
  role       = aws_iam_role.eventbridge_sqs_role.name
  policy_arn = aws_iam_policy.eventbridge_sqs_policy.arn
}

# -----------------------------------------------------------------------------
# EventBridge Rule
# -----------------------------------------------------------------------------
module "eventbridge_rule" {
  source = "./modules/eventbridge-rule"

  name        = "monitor-events-rule"
  description = "Capture all events starting with com.saas.monitor"
  bus_name    = module.eventbridge_bus.name
  event_pattern = jsonencode({
    source = [{ "prefix" : "com.saas.monitor" }]
  })

  targets = {
    "SendToCloudWatchLogs" = {
      arn      = module.cloudwatch_log_group.arn
      role_arn = aws_iam_role.eventbridge_logs_role.arn
    }
    "SendToSQS" = {
      arn      = module.sqs_queue.queue_arn
      role_arn = aws_iam_role.eventbridge_sqs_role.arn
    }
  }
  tags = var.tags
}
