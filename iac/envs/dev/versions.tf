terraform {
  required_version = ">= 1.8.0"

  backend "s3" {
    bucket         = "pedidos-pagos-dev-tfstate-132681090057"
    key            = "pedidos-pagos/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "pedidos-pagos-dev-tf-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}