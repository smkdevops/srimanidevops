resource "aws_ecs_task_definition" "EC2_task_defination" {
  count                 = var.launch_type == "EC2" ? 1 : 0
  family                = var.task_name
  container_definitions = file(var.container_definitions)
  task_role_arn         = var.task_role_arn
  execution_role_arn    = var.execution_role_arn
  network_mode          = var.network_mode
  tags = merge(var.tags, module.mandatory_tags.tags)
}

resource "aws_ecs_task_definition" "FARGATE_task_defination" {
  count                    = var.launch_type == "FARGATE" ? 1 : 0
  family                   = var.task_name
  task_role_arn            = var.task_role_arn
  execution_role_arn       = var.execution_role_arn
  network_mode             = var.network_mode
  requires_compatibilities = [var.launch_type]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  container_definitions    = file(var.container_definitions)
  tags = merge(var.tags, module.mandatory_tags.tags)
}

