variable "aws_primary_region" {
    type = string
    default = "eu-north-1"
}

variable "aws_secondary_region" {
    type = string
    default = "eu-west-1"
}

variable "ec2_instance_type" {
    type = string
    default = "t2.micro" 
}

variable "admin_cidr" {
    type = string
    sensitive = true
}
