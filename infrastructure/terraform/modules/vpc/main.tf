# VPC Terraform Module

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = "kubechamp-${var.environment}-vpc"
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "kubechamp-${var.environment}-igw"
    }
  )
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "kubechamp-${var.environment}-public-subnet-${count.index + 1}"
      Type = "Public"
    }
  )
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name = "kubechamp-${var.environment}-private-subnet-${count.index + 1}"
      Type = "Private"
    }
  )
}

# Elastic IPs for NAT Gateway
resource "aws_eip" "nat" {
  count  = length(var.public_subnets)
  domain = "vpc"

  depends_on = [aws_internet_gateway.main]

  tags = merge(
    var.tags,
    {
      Name = "kubechamp-${var.environment}-eip-${count.index + 1}"
    }
  )
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count         = length(var.public_subnets)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  depends_on = [aws_internet_gateway.main]

  tags = merge(
    var.tags,
    {
      Name = "kubechamp-${var.environment}-nat-${count.index + 1}"
    }
  )
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.main.id
  }

  tags = merge(
    var.tags,
    {
      Name = "kubechamp-${var.environment}-public-rt"
    }
  )
}

# Private Route Tables (per AZ for high availability)
resource "aws_route_table" "private" {
  count  = length(var.private_subnets)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(
    var.tags,
    {
      Name = "kubechamp-${var.environment}-private-rt-${count.index + 1}"
    }
  )
}

# Public Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Table Associations
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# VPC Endpoints for AWS services (saves on NAT gateway costs)
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  tags = merge(
    var.tags,
    {
      Name = "kubechamp-${var.environment}-s3-endpoint"
    }
  )
}

resource "aws_vpc_endpoint_route_table_association" "s3" {
  count           = length(aws_route_table.private)
  route_table_id  = aws_route_table.private[count.index].id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

# VPC Flow Logs for network monitoring
resource "aws_flow_log_role" "main" {
  name = "kubechamp-vpc-flow-logs-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_flow_log_resource_policy" "main" {
  resource_arn    = aws_flow_log_role.main.arn
  retention_in_days = var.environment == "prod" ? 90 : 30
}

resource "aws_flow_log" "main" {
  iam_role_arn    = aws_flow_log_role.main.arn
  log_destination = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/vpc/flowlogs"
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "kubechamp-${var.environment}-flow-logs"
    }
  )
}

# Data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# DB Subnet Group for RDS
resource "aws_db_subnet_group" "main" {
  name       = "kubechamp-${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = merge(
    var.tags,
    {
      Name = "kubechamp-${var.environment}-db-subnet-group"
    }
  )
}

# Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ips" {
  description = "NAT Gateway IP addresses"
  value       = aws_eip.nat[*].public_ip
}

output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.main.name
}
