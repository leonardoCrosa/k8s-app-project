# Configure the AWS Provider
provider "aws" {
  region  = var.region
  profile = "lcrosa"
}
variable "region" {
  type    = string
  default = "us-east-1"
}
