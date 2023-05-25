resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = var.config_map_name
    namespace = var.namespace
  }

  data = {
    mapRoles = var.enable_karpenter == true ? yamlencode(distinct(concat(local.configmap_roles,var.additional_roles,local.karpenter_role))) : yamlencode(distinct(concat(local.configmap_roles,var.additional_roles)))
  }

  lifecycle {
    ignore_changes = [data]
  }
  depends_on = [null_resource.wait_for_cluster]
}

locals {
  configmap_roles = [
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.master_user}"
      username = "${var.master_user}:{{SessionName}}"
      groups = [
        "system:masters"
      ]

    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/antm-caas-readonly"
      username = "antm-caas-readonly:{{SessionName}}"
      groups = [
        "system:masters"
      ]
    }
  ]
  karpenter_role = [
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-karpenter-role"
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers","system:nodes"
      ]
    }    
  ]  
}

resource "null_resource" "wait_for_cluster" {
  depends_on = [aws_eks_cluster.eks_cluster]
  provisioner "local-exec" {
    command     = "for i in `seq 1 60`; do wget --no-check-certificate -O - -q $ENDPOINT/healthz >/dev/null && exit 0 || true; sleep 5; done; echo TIMEOUT && exit 1"
    interpreter = ["/bin/sh", "-c"]
    environment = {
      ENDPOINT = aws_eks_cluster.eks_cluster.endpoint
    }

  }

}
