data "aws_vpc" "selected" {}

data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name   = "tag:noam"
    values = ["1"]
  }
}

data "aws_caller_identity" "current" {}
