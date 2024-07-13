import iam
import vpc
import pulumi
from pulumi_aws import eks

eks_cluster = eks.Cluster(
    'eks-cluster',
    role_arn=iam.eks_role.arn,
    tags={
        'Name': 'pulumi-eks-cluster',
    },
    vpc_config=eks.ClusterVpcConfigArgs(
        public_access_cidrs=['0.0.0.0/0'],
        security_group_ids=[vpc.eks_security_group.id],
        subnet_ids=vpc.subnet_ids,
    ),
)

eks_node_group_default = eks.NodeGroup(
    'eks-node-group-default',
    cluster_name=eks_cluster.name,
    node_group_name='pulumi-eks-nodegroup-default',
    instance_types=["t3.medium"],
    capacity_type="SPOT",
    ami_type="AL2_x86_64",
    node_role_arn=iam.ec2_role.arn,
    subnet_ids=vpc.subnet_ids,
    tags={
        'Name': 'pulumi-cluster-nodeGroup-default',
    },
    scaling_config=eks.NodeGroupScalingConfigArgs(
        desired_size=1,
        max_size=2,
        min_size=1,
    ),
)

eks_node_group_gpu = eks.NodeGroup(
    'eks-node-group-gpu',
    cluster_name=eks_cluster.name,
    node_group_name='pulumi-eks-nodegroup-gpu',
    instance_types=["g4dn.xlarge"],
    capacity_type="SPOT",
    ami_type="BOTTLEROCKET_x86_64_NVIDIA",
    node_role_arn=iam.ec2_role.arn,
    subnet_ids=vpc.subnet_ids,
    tags={
        'Name': 'pulumi-cluster-nodeGroup-default',
    },
    scaling_config=eks.NodeGroupScalingConfigArgs(
        desired_size=1,
        max_size=2,
        min_size=1,
    ),
)

# make private subnets for nodegroups
# deploy gpu-operator
# deploy app
# check app
# add taints
# add tolerations
