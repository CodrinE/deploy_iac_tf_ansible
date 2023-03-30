terraform {
  required_version = ">=0.14.0"
  backend "s3" {
    region  = "eu-central-1"
    profile = "default"
    key     = "terraformstatefile"
    bucket  = "terraformstatebucket-0001"
  }
}
