output "asg_id" {
  value       = aws_autoscaling_group.ecs-autoscaling-group.*.id
  description = "The autoscaling group id."
}

output "asg_arn" {
  value       = aws_autoscaling_group.ecs-autoscaling-group.*.arn
  description = "The ARN for this AutoScaling Group"
}

output "asg_availability_zones" {
  value       = aws_autoscaling_group.ecs-autoscaling-group.*.availability_zones
  description = "The availability zones of the autoscale group."
}

output "asg_max_size" {
  value       = aws_autoscaling_group.ecs-autoscaling-group.*.max_size
  description = "The maximum size of the autoscale group."
}

output "asg_min_size" {
  value       = aws_autoscaling_group.ecs-autoscaling-group.*.min_size
  description = "The minimum size of the autoscale group."
}

output "asg_default_cooldown" {
  value       = aws_autoscaling_group.ecs-autoscaling-group.*.default_cooldown
  description = "Time between a scaling activity and the succeeding scaling activity."
}

output "asg_name" {
  value       = aws_autoscaling_group.ecs-autoscaling-group.*.name
  description = "The name of the autoscale group"
}

output "asg_health_check_grace_period" {
  value       = aws_autoscaling_group.ecs-autoscaling-group.*.health_check_grace_period
  description = "Time after instance comes into service before checking health."
}

output "asg_health_check_type" {
  value       = aws_autoscaling_group.ecs-autoscaling-group.*.health_check_type
  description = "EC2 or ELB. Controls how health checking is done."
}

output "asg_desired_capacity" {
  value       = aws_autoscaling_group.ecs-autoscaling-group.*.desired_capacity
  description = "The number of Amazon EC2 instances that should be running in the group."
}

output "asg_launch_configuration" {
  value       = aws_autoscaling_group.ecs-autoscaling-group.*.launch_configuration
  description = "The launch configuration of the autoscale group"
}

output "asg_vpc_zone_identifier" {
  value       = aws_autoscaling_group.ecs-autoscaling-group.*.vpc_zone_identifier
  description = "The VPC zone identifier"
}

output "asg_load_balancers" {
  value       = aws_autoscaling_group.ecs-autoscaling-group.*.load_balancers
  description = "The load balancer names associated with the autoscaling group."
}

output "asg_target_group_arns" {
  value       = aws_autoscaling_group.ecs-autoscaling-group.*.target_group_arns
  description = "list of Target Group ARNs that apply to this AutoScaling Group"
}

output "lc_id" {
  value       = aws_launch_configuration.ecs-launch-config.*.id
  description = "The ID of the launch configuration."
}

output "lc_name" {
  value       = aws_launch_configuration.ecs-launch-config.*.name
  description = "The name of the launch configuration."
}

output "ecs-cluster-id" {
  value       = aws_ecs_cluster.ecs-cluster.id
  description = "The Amazon Resource Name (ARN) that identifies the cluster"
}

output "ecs-cluster-arn" {
  value       = aws_ecs_cluster.ecs-cluster.arn
  description = "The Amazon Resource Name (ARN) that identifies the cluster"
}

output "ec2-ecs-service-id" {
  value       = aws_ecs_service.EC2_ecs-service.*.id
  description = "The Amazon Resource Name (ARN) that identifies the service"
}

output "ec2-ecs-service-name" {
  value       = aws_ecs_service.EC2_ecs-service.*.name
  description = "The name of the service"
}

output "ec2-ecs-service-cluster" {
  value       = aws_ecs_service.EC2_ecs-service.*.cluster
  description = "The Amazon Resource Name (ARN) of cluster which the service runs on"
}

output "ec2-ecs-service-iam_role" {
  value       = aws_ecs_service.EC2_ecs-service.*.iam_role
  description = "The ARN of IAM role used for ELB"
}

output "ec2-ecs-service-desired_count" {
  value       = aws_ecs_service.EC2_ecs-service.*.desired_count
  description = "The number of instances of the task definition"
}

output "fargate-ecs-service-id" {
  value       = aws_ecs_service.FARGATE_ecs_service.*.id
  description = "The Amazon Resource Name (ARN) that identifies the service"
}

output "fargate-ecs-service-name" {
  value       = aws_ecs_service.FARGATE_ecs_service.*.name
  description = "The name of the service"
}

output "fargate-ecs-service-cluster" {
  value       = aws_ecs_service.FARGATE_ecs_service.*.cluster
  description = "The Amazon Resource Name (ARN) of cluster which the service runs on"
}

output "fargate-ecs-service-iam_role" {
  value       = aws_ecs_service.FARGATE_ecs_service.*.iam_role
  description = "The ARN of IAM role used for ELB"
}

output "fargate-ecs-service-desired_count" {
  value       = aws_ecs_service.FARGATE_ecs_service.*.desired_count
  description = "The number of instances of the task definition"
}

output "ec2-task-defination_arn" {
  value       = aws_ecs_task_definition.EC2_task_defination.*.arn
  description = "Full ARN of the Task Definition (including both family and revision)."
}

output "ec2-task-defination_family" {
  value       = aws_ecs_task_definition.EC2_task_defination.*.family
  description = "The family of the Task Definition."
}

output "ec2-task-defination_revision" {
  value       = aws_ecs_task_definition.EC2_task_defination.*.revision
  description = "The revision of the task in a particular family."
}

output "fargate-task-defination_arn" {
  value       = aws_ecs_task_definition.EC2_task_defination.*.arn
  description = "Full ARN of the Task Definition (including both family and revision)."
}

output "fargate-task-defination_family" {
  value       = aws_ecs_task_definition.EC2_task_defination.*.family
  description = "The family of the Task Definition."
}

output "fargate-task-defination_revision" {
  value       = aws_ecs_task_definition.EC2_task_defination.*.revision
  description = "The revision of the task in a particular family."
}

