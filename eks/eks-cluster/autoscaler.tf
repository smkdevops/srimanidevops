module "cluster-autoscaler" {
  source                            = "./cluster-autoscaler"
  count                             = var.enable_karpenter ? 0 : 1
  assume_role_policy_autoscaler     = var.assume_role_policy_autoscaler
  managed_policy_arns_autoscaler    = var.managed_policy_arns_autoscaler
  cluster_autoscaler_image_tag      = var.cluster_autoscaler_image_tag
  cluster_name                      = split(":", module.fargate_profile.id)[0]
  cluster_autoscaler_name           = var.cluster_autoscaler_name
  cluster_autoscaler_chart          = var.cluster_autoscaler_chart
  cluster_autoscaler_repository     = var.cluster_autoscaler_repository
  cluster_autoscaler_namespace      = var.cluster_autoscaler_namespace
  cluster_autoscaler_helm_version   = var.cluster_autoscaler_helm_version
  cluster_autoscaler_timeout        = var.cluster_autoscaler_timeout
  eks_oidc_issuer_url               = replace(aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "https://", "")
  tags                              = var.tags
}    

module "karpenter" {
  source                            = "./karpenter"
  count                             = var.enable_karpenter ? 1 : 0
  cluster_name                      = split(":", module.fargate_profile.id)[0]
  cluster_endpoint                  = aws_eks_cluster.eks_cluster.endpoint
  eks_oidc_issuer_url               = replace(aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "https://", "")
  cluster_security_group            = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
  vpc_id                            = var.vpc_id
  subnet_ids                        = var.subnet_ids == null ? data.aws_subnets.private.ids : var.subnet_ids
  karpenter_name                    = var.karpenter_name
  karpenter_chart                   = var.karpenter_chart
  karpenter_repository              = var.karpenter_repository
  karpenter_namespace               = var.karpenter_namespace
  karpenter_helm_version            = var.karpenter_helm_version
  karpenter_timeout                 = var.karpenter_timeout
  karpenter_instance_profile        = var.karpenter_instance_profile
  tags                              = var.tags
}
