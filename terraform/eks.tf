locals {
  environment            = "dev"
  cluster_name           = "ml-${local.environment}"
  gpu_operator_namespace = "gpu-operator"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name = local.cluster_name
  cluster_version = "1.29"

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  tags = {
    Environment = local.environment
    Terraform   = "true"
  }

  depends_on = [module.vpc]
}

module "eks_managed_node_group_gpu" {
  # count  = 0
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "20.8.4"

  name            = "${local.cluster_name}-gpu-nodes"
  cluster_name    = local.cluster_name
  cluster_version = module.eks.cluster_version

  subnet_ids = module.vpc.private_subnets

  // The following variables are necessary if you decide to use the module outside of the parent EKS module context.
  // Without it, the security groups of the nodes are empty and thus won't join the cluster.
  cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
  vpc_security_group_ids            = [module.eks.node_security_group_id]
  cluster_service_cidr              = module.eks.cluster_service_cidr

  min_size     = 1
  max_size     = 1
  desired_size = 1

  instance_types = ["g4dn.xlarge"]
  ami_type       = "BOTTLEROCKET_x86_64_NVIDIA" 
  # ami_id         = "ami-078ce101c2c6e6bb0"
  capacity_type = "ON_DEMAND"

  block_device_mappings = {
    xvda = {
      device_name = "/dev/xvda"
      ebs = {
        volume_size           = 50
        volume_type           = "gp3"
        iops                  = 3000
        throughput            = 150
        delete_on_termination = true
        ebs_optimized         = true
      }
    }
  }

  labels = {
    Environment = local.environment
  }

  taints = {
    dedicated = {
      key    = "dedicated"
      value  = "gpuGroup"
      effect = "NO_SCHEDULE"
    }
  }

  tags = {
    Environment = local.environment
    Terraform   = "true"
  }

  depends_on = [module.eks]
}

module "eks_managed_node_group_default" {
  # count  = 0
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "20.8.4"

  name            = "${local.cluster_name}-default-nodes"
  cluster_name    = local.cluster_name
  cluster_version = module.eks.cluster_version

  subnet_ids = module.vpc.private_subnets

  // The following variables are necessary if you decide to use the module outside of the parent EKS module context.
  // Without it, the security groups of the nodes are empty and thus won't join the cluster.
  cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
  vpc_security_group_ids            = [module.eks.node_security_group_id]
  cluster_service_cidr              = module.eks.cluster_service_cidr

  min_size     = 0
  max_size     = 1
  desired_size = 1

  instance_types = ["t3.small"]
  ami_type       = "AL2_x86_64"
  capacity_type  = "SPOT"

  labels = {
    Environment = local.environment
  }

  tags = {
    Environment = local.environment
    Terraform   = "true"
  }

  depends_on = [module.vpc]
}
