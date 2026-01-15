variable "aws_region" {
  description = "AWS region for deployment"
  type = string
  default = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance size"
  type = string
  default = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID for Amazon Linux 2023"
  type = string
  default = "ami-0ced6a024bb18ff2e"
}

variable "key_name" {
  description = "The name of the SSH key pair"
  type = string
  default ="tf-keypair"
}


