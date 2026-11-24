terraform {
  backend "s3" {
    bucket = "my-terraform-state-bucket-uniq"
    key    = "terraform.tfstate"
    region = "eu-north-1"
    encrypt = true
    use_lockfile = true 
  }
}