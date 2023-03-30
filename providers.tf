provider "aws" {
  profile = var.profile
  region  = var.master-region
  alias   = "master-region"
}
provider "aws" {
  profile = var.profile
  region  = var.worker-region
  alias   = "worker-region"
}