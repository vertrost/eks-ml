locals {
  cluster_name           = "ml"
  gpu_operator_namespace = "gpu-operator"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name = local.cluster_name
  # cluster_version = "1.29"
  cluster_version = "1.25"

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

  #   access_entries = {
  #     # One access entry with a policy associated
  #     example = {
  #       kubernetes_groups = []
  #       principal_arn     = "arn:aws:iam::381491841187:user/szhekpisov"

  #       policy_associations = {
  #         example = {
  #           policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
  #           access_scope = {
  #             namespaces = ["default"]
  #             type       = "namespace"
  #           }
  #         }
  #       }
  #     }
  #   }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

module "eks_managed_node_group" {
  # count  = 0
  source = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"

  name            = "${local.cluster_name}-nodes"
  cluster_name    = local.cluster_name
  cluster_version = module.eks.cluster_version

  subnet_ids = module.vpc.private_subnets

  // The following variables are necessary if you decide to use the module outside of the parent EKS module context.
  // Without it, the security groups of the nodes are empty and thus won't join the cluster.
  cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
  vpc_security_group_ids            = [module.eks.node_security_group_id]
  cluster_service_cidr              = module.eks.cluster_service_cidr

  // Note: `disk_size`, and `remote_access` can only be set when using the EKS managed node group default launch template
  // This module defaults to providing a custom launch template to allow for custom security groups, tag propagation, etc.
  // use_custom_launch_template = false
  // disk_size = 50
  //
  //  # Remote access cannot be specified with a launch template
  //  remote_access = {
  //    ec2_ssh_key               = module.key_pair.key_pair_name
  //    source_security_group_ids = [aws_security_group.remote_access.id]
  //  }

  min_size     = 0
  max_size     = 1
  desired_size = 0

  instance_types = ["g4dn.xlarge"]
  ami_type       = "AL2_x86_64_GPU"
  # ami_id         = "ami-00a9ec5cda5e3ffa8"
  capacity_type = "ON_DEMAND"

  labels = {
    Environment = "dev"
  }

  taints = {
    dedicated = {
      key    = "dedicated"
      value  = "gpuGroup"
      effect = "NO_SCHEDULE"
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

module "eks_managed_node_group_default" {
  # count  = 0
  source = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"

  name            = "${local.cluster_name}-default-nodes"
  cluster_name    = local.cluster_name
  cluster_version = module.eks.cluster_version

  subnet_ids = module.vpc.private_subnets

  // The following variables are necessary if you decide to use the module outside of the parent EKS module context.
  // Without it, the security groups of the nodes are empty and thus won't join the cluster.
  cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
  vpc_security_group_ids            = [module.eks.node_security_group_id]
  cluster_service_cidr              = module.eks.cluster_service_cidr

  // Note: `disk_size`, and `remote_access` can only be set when using the EKS managed node group default launch template
  // This module defaults to providing a custom launch template to allow for custom security groups, tag propagation, etc.
  // use_custom_launch_template = false
  // disk_size = 50
  //
  //  # Remote access cannot be specified with a launch template
  //  remote_access = {
  //    ec2_ssh_key               = module.key_pair.key_pair_name
  //    source_security_group_ids = [aws_security_group.remote_access.id]
  //  }

  min_size     = 0
  max_size     = 1
  desired_size = 1

  instance_types = ["t3.small"]
  ami_type       = "AL2_x86_64"
  capacity_type  = "SPOT"

  labels = {
    Environment = "dev"
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

  