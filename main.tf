# -----------------------------------------------------------------------------
# EventBridge Custom Bus
# -----------------------------------------------------------------------------
module "eventbridge_bus" {
  source = "./modules/eventbridge-bus"

  name = "ops-main-cust-bus"
  tags = var.tags

  archive_config = {
    enabled        = true
    name           = "ops-main-bus-archive"
    retention_days = 30
    event_pattern = jsonencode({
      source = [{ "prefix" : "com.saas.monitor" }]
    })
  }
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

# Resource Policy for CloudWatch Logs
# EventBridge requires a resource policy on CloudWatch Logs to allow writing events.
data "aws_iam_policy_document" "logs_resource_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    resources = ["${module.cloudwatch_log_group.arn}:*"]
  }
}

resource "aws_cloudwatch_log_resource_policy" "logging_policy" {
  policy_name     = "saas-monitor-eventbridge-policy"
  policy_document = data.aws_iam_policy_document.logs_resource_policy_doc.json
}

# -----------------------------------------------------------------------------
# SQS Target
# -----------------------------------------------------------------------------
module "sqs_queue" {
  source = "./modules/sqs-queue"

  name                        = "update-omnibus.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  dlq_config = {
    enabled           = true
    name              = "update-omnibus-dlq.fifo"
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
      role_arn = null
    }
    "SendToSQS" = {
      arn              = module.sqs_queue.queue_arn
      role_arn         = aws_iam_role.eventbridge_sqs_role.arn
      message_group_id = "monitor-events"
    }
  }
  tags = var.tags
}

# -----------------------------------------------------------------------------
# Lambda Layer
# -----------------------------------------------------------------------------
resource "aws_lambda_layer_version" "observability_cert" {
  filename            = "${path.module}/src/update_omnibus/observability-cert.zip"
  layer_name          = "observability-cert"
  compatible_runtimes = ["python3.9"]
}

# -----------------------------------------------------------------------------
# Lambda Function - Update Omnibus
# -----------------------------------------------------------------------------
module "update_omnibus_lambda" {
  source = "./modules/lambda"

  name    = "update-omnibus"
  handler = "update_omnibus.lambda_handler"
  runtime = "python3.9"

  source_config = {
    path = "${path.module}/src/update_omnibus/update_omnibus.py"
    type = "file"
  }

  layers = [aws_lambda_layer_version.observability_cert.arn]

  environment_variables = {
    OMNIBUS_URL   = "https://example.com/omnibus" # Placeholder
    CERT_PATH     = "/opt/cert.pem"               # Asset path
    SQS_QUEUE_URL = module.sqs_queue.queue_url
  }

  tags = var.tags

  additional_policies = [
    jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "sqs:ReceiveMessage",
            "sqs:DeleteMessage",
            "sqs:GetQueueAttributes"
          ]
          Effect   = "Allow"
          Resource = module.sqs_queue.queue_arn
        }
      ]
    })
  ]
}

# -----------------------------------------------------------------------------
# EventBridge Scheduler for Lambda
# -----------------------------------------------------------------------------
resource "aws_iam_role" "scheduler_role" {
  name = "update-omnibus-scheduler-role"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "scheduler_policy" {
  name        = "update-omnibus-scheduler-policy"
  description = "Allow Scheduler to invoke Lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "lambda:InvokeFunction"
        Effect   = "Allow"
        Resource = module.update_omnibus_lambda.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "scheduler_attach" {
  role       = aws_iam_role.scheduler_role.name
  policy_arn = aws_iam_policy.scheduler_policy.arn
}

resource "aws_scheduler_schedule" "lambda_schedule" {
  name       = "update-omnibus-schedule"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "rate(5 minutes)"

  target {
    arn      = module.update_omnibus_lambda.arn
    role_arn = aws_iam_role.scheduler_role.arn

    retry_policy {
      maximum_event_age_in_seconds = 300
      maximum_retry_attempts       = 0 # Let Lambda retry/DLQ handle failures or SQS retention
    }
  }
}
