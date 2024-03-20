
data "aws_eks_cluster" "default" {
  name = local.cluster_name
}

provider "kubernetes" {
  host = data.aws_eks_cluster.default.endpoint

  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
    command     = "aws"
  }
}

resource "kubernetes_namespace" "gpu-operator" {
  metadata {
    annotations = {
      name = local.gpu_operator_namespace
    }

    name = local.gpu_operator_namespace
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.default.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
      command     = "aws"
    }
  }
}

resource "helm_release" "nvidia" {
    count = 0
  name       = "nvidia"
  repository = "https://helm.ngc.nvidia.com/nvidia"
  chart      = local.gpu_operator_namespace
  namespace  = "gpu-operator"
  version    = "v23.9.2"
}