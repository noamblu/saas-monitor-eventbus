# SaaS Monitor EventBus

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)

A modular Terraform project for deploying a robust EventBridge monitoring architecture on AWS. This project sets up a custom EventBus, routing rules, and multiple targets including CloudWatch Logs and SQS with Dead Letter Queues (DLQ).

## Architecture

```mermaid
graph TD
    Source[Event Source] -->|PutEvents| Bus[Custom EventBus]
    Bus -->|Rule: com.saas.monitor.*| Rule{Event Rule}
    
    Rule -->|Target 1| CW[CloudWatch Log Group]
    Rule -->|Target 2| SQS[SQS Queue]
    
    SQS -.->|Redrive Policy| DLQ[Dead Letter Queue]
    
    style Bus fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:white
    style CW fill:#E05243,stroke:#232F3E,stroke-width:2px,color:white
    style SQS fill:#FF4F8B,stroke:#232F3E,stroke-width:2px,color:white
    style DLQ fill:#FF4F8B,stroke:#232F3E,stroke-width:2px,color:white
```

## Features

- **Modular Design**: Each component (Bus, Queue, Logs, Rules) is a standalone Terraform module.
- **Resilience**: SQS queues come with configured Dead Letter Queues (DLQ) for failed message handling.
- **Observability**: All events are logged to CloudWatch Logs for debugging and audit.
- **Security**: IAM roles are scoped with least-privilege permissions.

## Modules

| Module | Description | Source |
|--------|-------------|--------|
| `eventbridge-bus` | Creates the custom EventBridge bus | `./modules/eventbridge-bus` |
| `eventbridge-rule` | Manages rules and targets | `./modules/eventbridge-rule` |
| `sqs-queue` | Deploys SQS queues with optional DLQ | `./modules/sqs-queue` |
| `cloudwatch-log-group` | Sets up Log Groups with retention | `./modules/cloudwatch-log-group` |

## Usage

To use this project, simply include the root module in your Terraform configuration:

```hcl
module "saas_monitor" {
  source = "./"

  aws_region = "eu-central-1"
  tags = {
    Project     = "SaaS-Monitor"
    Environment = "Production"
  }
}
```

### Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `aws_region` | The AWS region to deploy resources into | `string` | `eu-central-1` |
| `tags` | Common tags to apply to all resources | `map(string)` | `{...}` |

### Outputs

| Name | Description |
|------|-------------|
| `sqs_queue_url` | The URL of the main SQS queue |
| `sqs_dlq_url` | The URL of the Dead Letter Queue |

## Requirements

- Terraform >= 1.5
- AWS Provider >= 5.0

## License

MIT
