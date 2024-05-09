data "aws_eks_cluster" "default" {
  name = local.cluster_name

  depends_on = [module.eks]
}

resource "kubernetes_namespace" "gpu-operator" {
  metadata {
    annotations = {
      name = local.gpu_operator_namespace
    }

    name = local.gpu_operator_namespace
  }
}

# resource "kubernetes_namespace" "cluster-autoscaler" {
#   metadata {
#     annotations = {
#       name = "cluster-autoscaler"
#     }

#     name = "cluster-autoscaler"
#   }
# }

resource "helm_release" "nvidia" {
  name       = "nvidia"
  repository = "https://helm.ngc.nvidia.com/nvidia"
  chart      = local.gpu_operator_namespace
  namespace  = "gpu-operator"
  version    = "v23.9.1"

  set {
    name  = "node-feature-discovery.worker.tolerations[0].key"
    value = "dedicated"
  }

  set {
    name  = "node-feature-discovery.worker.tolerations[0].value"
    value = "gpuGroup"
  }

  set {
    name  = "node-feature-discovery.worker.tolerations[0].operator"
    value = "Equal"
  }

  set {
    name  = "node-feature-discovery.worker.tolerations[0].effect"
    value = "NoSchedule"
  }

  set {
    name  = "daemonsets.tolerations[0].key"
    value = "dedicated"
  }

  set {
    name  = "daemonsets.tolerations[0].value"
    value = "gpuGroup"
  }

  set {
    name  = "daemonsets.tolerations[0].operator"
    value = "Equal"
  }

  set {
    name  = "daemonsets.tolerations[0].effect"
    value = "NoSchedule"
  }
  set {
    name  = "operator.tolerations[0].key"
    value = "dedicated"
  }

  set {
    name  = "operator.tolerations[0].value"
    value = "gpuGroup"
  }

  set {
    name  = "operator.tolerations[0].operator"
    value = "Equal"
  }

  set {
    name  = "operator.tolerations[0].effect"
    value = "NoSchedule"
  }

  depends_on = [kubernetes_namespace.gpu-operator]
}

# resource "helm_release" "cluster_autoscaler" {
#   name       = "nvidia"
#   repository = "https://kubernetes.github.io/autoscaler"
#   chart      = "cluster-autoscaler"
#   namespace  = "cluster-autoscaler"
#   version    = "9.36.0"
#   depends_on = [kubernetes_namespace.cluster-autoscaler]
# }
