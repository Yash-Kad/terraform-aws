provider "aws" {
  region = var.aws_region
}

# --- VPC & Networking ---
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "ecs-vpc" }
}

resource "aws_subnet" "public" {
  count                   = var.az_count
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
  tags                    = { Name = "public-subnet-${count.index}" }
}

data "aws_availability_zones" "available" {}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

# --- ECR Repositories ---
resource "aws_ecr_repository" "backend" {
  name         = "flask-backend"
  force_delete = true
}

resource "aws_ecr_repository" "frontend" {
  name         = "express-frontend"
  force_delete = true
}

# --- CloudWatch Logs ---
resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/backend-task"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/frontend-task"
  retention_in_days = 7
}
