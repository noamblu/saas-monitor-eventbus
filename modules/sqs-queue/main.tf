resource "aws_sqs_queue" "dlq" {
  count = var.dlq_config.enabled ? 1 : 0

  name = var.dlq_config.name
  tags = var.tags
}

resource "aws_sqs_queue" "this" {
  name = var.name
  tags = var.tags

  redrive_policy = var.dlq_config.enabled ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = var.dlq_config.max_receive_count
  }) : null
}
