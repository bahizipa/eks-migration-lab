data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = [for i in range(2) : cidrsubnet(var.vpc_cidr, 4, i)]      # /20
  public_subnets  = [for i in range(2) : cidrsubnet(var.vpc_cidr, 8, 48 + i)] # /24
  db_subnets      = [for i in range(2) : cidrsubnet(var.vpc_cidr, 8, 64 + i)] # /24
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.13"

  name = var.project
  cidr = var.vpc_cidr
  azs  = local.azs

  private_subnets  = local.private_subnets
  public_subnets   = local.public_subnets
  database_subnets = local.db_subnets

  enable_nat_gateway = true
  single_nat_gateway = true # lab: one NAT to keep cost down (prod: one per AZ)
  enable_dns_hostnames = true

  create_database_subnet_group = true

  # Tags EKS needs to discover subnets for load balancers
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.project}"      = "shared"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.project}"      = "shared"
  }
}
