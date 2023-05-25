module "fargate_profile" {
  source                = "cps-terraform.anthem.com/DIG/terraform-aws-eks-fargate/aws"
  version               = "0.0.3"
  tags                  = var.tags
  cluster_name          = aws_eks_cluster.eks_cluster.id
  fargate_profile_name  = "autoscaler"
  subnet_ids            = var.subnet_ids == null ? data.aws_subnets.private.ids : var.subnet_ids
  namespaces_selector   = [
  {
    namespace = "karpenter"
    labels = {}
  },
  {
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/instance" = "cluster-autoscaler"
      "app.kubernetes.io/name"     = "aws-cluster-autoscaler"
    }
  }    
  ]
}


resource "kubernetes_namespace" "cloudwatch-logging" {
  depends_on       = [aws_eks_cluster.eks_cluster]
  metadata {
    labels = {
      aws-observability = "enabled"
    }
    name = "aws-observability"
  }
}

module "terraform-aws-kms-service-fargate" {
  source                   = "cps-terraform.anthem.com/DIG/terraform-aws-kms-service/aws"
  version                  = "0.2.0"
  description              = "EKS Fargate KMS Cloud Watch Key"
  kms_alias_name           = "${var.tags["application-name"]}-${var.tags["environment"]}-fargate-${var.cluster_name}"
  service_name             = ["logs"]
  tags                     = var.tags
}

resource "aws_cloudwatch_log_group" "eks_fargate_cloud_watch_log_group" {
  name                     = "${var.cluster_name}-fargate-profile-logs"
  retention_in_days        = var.fargate_log_retention_in_days
  skip_destroy             = var.fargate_log_skip_destroy
  kms_key_id               = module.terraform-aws-kms-service-fargate.kms_arn["logs"]
  tags                     = var.tags
}

resource "kubernetes_config_map" "logging" {
  depends_on      = [aws_eks_cluster.eks_cluster,kubernetes_namespace.cloudwatch-logging,aws_cloudwatch_log_group.eks_fargate_cloud_watch_log_group]
  metadata {
    name = "aws-logging"
    namespace = "aws-observability"
  }
  data = {
    "output.conf" = <<EOF
[OUTPUT]
  Name cloudwatch_logs
  Match *
  region ${data.aws_region.current.name}
  log_group_name ${var.cluster_name}-fargate-profile-logs
  log_stream_prefix from-eks-fargate-
  log_key log
  EOF
    "parsers.conf" = <<EOF
[PARSER]
  Name crio
  Format Regex
  Regex ^(?<time>[^ ]+) (?<stream>stdout|stderr) (?<logtag>P|F) (?<log>.*)$
  Time_Key time
  Time_Format %Y-%m-%dT%H:%M:%S.%L%z
  EOF
    "filters.conf" = <<EOF
[FILTER]
  Name parser
  Match *
  Key_name log
  Parser crio
  EOF
  }
}
