resource "aws_ecs_cluster" "ecs-cluster" {
  name = var.ecs_cluster
  tags = merge(var.tags, module.mandatory_tags.tags)
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

