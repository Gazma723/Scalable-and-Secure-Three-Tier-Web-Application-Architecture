terraform {
  backend "s3" {
    bucket = "nexsecure-app"
    key    = "State-Files/terraform.tfstate"
    region = "us-east-1"
  }
}
