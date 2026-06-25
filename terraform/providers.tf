terraform {
  backend "s3" {
    bucket         = "vastraco-terraform-state-63f1696f"
    key            = "state/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "vastraco-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
