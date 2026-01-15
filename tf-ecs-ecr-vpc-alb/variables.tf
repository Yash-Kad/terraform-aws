variable "aws_region" {
  description = "Target AWS Region"
  type        = string
  default     = "ap-south-1"
}

variable "account_id" {
  description = "Your AWS Account ID for ECR URLs"
  type        = string
}

variable "az_count" {
  description = "Number of Availability Zones to use"
  default     = "2"
}
