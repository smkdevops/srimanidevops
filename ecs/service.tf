resource "aws_ecs_service" "EC2_ecs-service" {
  count   = var.launch_type == "EC2" ? 1 : 0
  name    = var.service_name
  cluster = aws_ecs_cluster.ecs-cluster.id

  task_definition 					= aws_ecs_task_definition.EC2_task_defination[0].arn
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  desired_count                      = var.desired_count
  launch_type                        = var.launch_type
  iam_role                           = var.ecs_service_iam_role
  scheduling_strategy                = var.scheduling_strategy

          
  dynamic load_balancer {
    for_each = var.target_group_arn == "" ? [] : [var.target_group_arn]
    content {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
    }
  } 

  deployment_controller {
    type = var.deployment_controller_type
  }
  tags = merge(var.tags, module.mandatory_tags.tags)
}

resource "aws_ecs_service" "FARGATE_ecs_service" {
  count   = var.launch_type == "FARGATE" ? 1 : 0
  name    = var.service_name
  cluster = aws_ecs_cluster.ecs-cluster.id

  task_definition = aws_ecs_task_definition.FARGATE_task_defination[0].arn
  desired_count = var.desired_count
  launch_type   = var.launch_type
  iam_role      = var.network_mode == "awsvpc" ? "" : var.ecs_service_iam_role

  network_configuration {
    security_groups = var.security_group_ids
    subnets         = var.subnet_ids
  }

  
  dynamic load_balancer {
    for_each = var.target_group_arn == "" ? [] : [var.target_group_arn]
    content {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
    }
  } 
  
  deployment_controller {
    type = var.deployment_controller_type
  }
  tags = merge(var.tags, module.mandatory_tags.tags)
}

