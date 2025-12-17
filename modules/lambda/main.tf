data "archive_file" "zip" {
  type        = "zip"
  source_file = var.source_config.type == "file" ? var.source_config.path : null
  source_dir  = var.source_config.type == "dir" ? var.source_config.path : null
  output_path = "${path.module}/${var.name}.zip"
}

resource "aws_iam_role" "this" {
  name = "${var.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  count      = var.vpc_config != null ? 1 : 0
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_policy" "additional" {
  count       = length(var.additional_policies)
  name_prefix = "${var.name}-policy-${count.index}"
  policy      = var.additional_policies[count.index]
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "additional" {
  count      = length(var.additional_policies)
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.additional[count.index].arn
}

resource "aws_lambda_function" "this" {
  filename         = data.archive_file.zip.output_path
  function_name    = var.name
  role             = aws_iam_role.this.arn
  handler          = var.handler
  source_code_hash = data.archive_file.zip.output_base64sha256
  runtime          = var.runtime
  tags             = var.tags
  timeout          = var.timeout
  layers           = var.layers

  environment {
    variables = var.environment_variables
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }
}

resource "aws_lambda_function_url" "this" {
  count              = var.create_url ? 1 : 0
  function_name      = aws_lambda_function.this.function_name
  authorization_type = "NONE"
}
