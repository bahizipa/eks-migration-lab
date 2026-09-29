module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name    = var.project
  cluster_version = var.cluster_version

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  # Lab convenience. In a real central platform this would be private + VPN/bastion.
  cluster_endpoint_public_access = true

  # Grants the identity running terraform cluster-admin via EKS Access Entries.
  enable_cluster_creator_admin_permissions = true
  authentication_mode                      = "API_AND_CONFIG_MAP"

  cluster_addons = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = { most_recent = true }
    eks-pod-identity-agent = {}
  }

  eks_managed_node_groups = {
    default = {
      instance_types = [var.node_instance_type]
      min_size       = 1
      max_size       = 3
      desired_size   = var.node_desired
      labels         = { workload = "general" }
    }
  }

  # Allow nodes to reach RDS (SG rule lives in rds.tf); allow NLB health checks.
  node_security_group_additional_rules = {
    ingress_nodeport_from_vpc = {
      description = "NLB health checks / NodePort traffic from inside the VPC"
      protocol    = "tcp"
      from_port   = 30000
      to_port     = 32767
      type        = "ingress"
      cidr_blocks = [var.vpc_cidr]
    }
  }
}
