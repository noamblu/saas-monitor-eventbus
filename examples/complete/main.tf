module "complete_example" {
  source = "../../"

  aws_region = "eu-central-1"
  tags = {
    Project     = "Example"
    Environment = "Test"
  }
}
