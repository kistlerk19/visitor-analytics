terraform {
  backend "s3" {
    bucket = "visitor-analytics-terraform-state-412381770444"
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }
}
