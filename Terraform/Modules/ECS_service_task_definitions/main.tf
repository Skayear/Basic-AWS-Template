#######################################################
## Shared resources between EC2 and FARGATE lunch type
####################################################### 
resource "aws_ecs_service" "service" {
  name            = var.service_full_name
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = var.ecs_desired_capacity
  launch_type     = var.service_launch_type
  cluster         = var.cluster_id

  deployment_minimum_healthy_percent = 50

  # dynamic "load_balancer" {
  #   for_each = [ for container in var.container_list: container if container.load_balancer_target_group_arn != null && container.load_balancer_target_group_arn != "" ]

  #   content {
  #     target_group_arn = load_balancer.value.load_balancer_target_group_arn
  #     container_name   = load_balancer.value.container_name
  #     container_port   = load_balancer.value.container_port
  #   }
  # }
  /*
  network_configuration {
    security_groups  = concat([aws_security_group.ecs_tasks.id], var.aux_access_sg)
    subnets          = var.subnet_ids
    assign_public_ip = false
  }*/
 
  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}
 
resource "aws_ecs_task_definition" "task_definition" {
  family                   = var.service_full_name
  requires_compatibilities = [var.service_launch_type]
  network_mode             = var.task_definition_network_mode
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  
  cpu                      = sum([for container in var.container_list: container.cpu])
  memory                   = sum([for container in var.container_list: container.memory])  

  container_definitions = jsonencode([for container in var.container_list: {
    name        = container.container_name 
    image       = "${container.ecr_repository_url}:latest"
    links       = container.links
    cpu         = container.cpu
    memory      = container.memory
    essential   = true

    #secrets = container.container_env_parameters != null ? jsondecode("[${join(",",[for param in container.container_env_parameters: "{ \"name\":\"${param.name}\" , \"valueFrom\":\"arn:aws:ssm:${var.region}:${var.account_id}:parameter/${var.env_name}/${var.service_full_name}/${param.name}\" }"]) }]" ) : []
    
    portMappings = [{
      protocol      = "tcp"
      containerPort = container.container_port
      hostPort      = 0
    }]

    # logConfiguration = {
    #   logDriver = "awslogs",
    #   options = {
    #     awslogs-group = container.cloudwatch_log_group
    #     awslogs-region = var.region
    #     awslogs-stream-prefix = container.container_name
    #   }
    # }  
  }])

} 

resource "aws_security_group" "ecs_tasks" {
  name   = "${var.service_full_name}-sg-task"
  vpc_id = var.vpc_id
 
  dynamic "ingress" {
    for_each = var.container_list

    content {
      protocol         = "tcp"
      from_port        = ingress.value.container_port
      to_port          = ingress.value.container_port
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  } 
 
  egress {
   protocol         = "-1"
   from_port        = 0
   to_port          = 0
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.env_full_name}-sg-task"
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.service_full_name}-ecsTaskExecutionRole"
 
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}
 
resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
 
resource "aws_iam_role_policy_attachment" "ecs-task-execution-rol-policy-attachment-SSMFullAccess" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.service_full_name}-ecsTaskRole"
 
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}
 
resource "aws_iam_policy" "task_policy" {
  name        = "${var.service_full_name}-task-policy"
  description = "Policy used to run the ECS task"
 
  policy = jsonencode({  
            Version = "2012-10-17",
            Statement = [{
                  Effect= "Allow",
                  Action=  [
                    "ssm:GetParameters", 
                    "kms:Decrypt"
                  ],
                  Resource = [
                    "*"
                   # join(",",[for param in var.container_env_parameters:  "arn:aws:ssm:${var.region}:${var.account_id}:parameter/${var.env_name}/${param.name}"])
                  ] 
            }]
          }) 
}
 
resource "aws_iam_role_policy_attachment" "ecs-task-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.task_policy.arn
}
 
resource "aws_iam_role_policy_attachment" "ecs-task-rol-policy-attachment-taskExecution" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs-task-rol-policy-attachment-SSMFullAccess" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
} 



# ------------------------------------------------------------------------------
# AWS Auto Scaling - CloudWatch Alarm CPU High
# ------------------------------------------------------------------------------
# resource "aws_cloudwatch_metric_alarm" "service_cpu_high" {
#   alarm_name          = "${var.service_full_name}_cpu_utilization_high"
#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   evaluation_periods  = "2" #var.max_cpu_evaluation_period
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/ECS"
#   period              = "60"#var.max_cpu_period
#   statistic           = "Maximum"
#   threshold           = "80"#var.max_cpu_threshold
  
#   dimensions = {
#     ClusterName = var.cluster_name
#     ServiceName = aws_ecs_service.service.name
#   }
#   alarm_actions = [aws_appautoscaling_policy.scale_up_policy.arn]

#   #tags = var.tags
# }

# ------------------------------------------------------------------------------
# AWS Auto Scaling - CloudWatch Alarm CPU Low
# ------------------------------------------------------------------------------
# resource "aws_cloudwatch_metric_alarm" "cpu_low" {
#   alarm_name          = "${var.service_full_name}_cpu_utilization_low"
#   comparison_operator = "LessThanOrEqualToThreshold"
#   evaluation_periods  = "4"#var.min_cpu_evaluation_period
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/ECS"
#   period              = "120"#var.min_cpu_period
#   statistic           = "Average"
#   threshold           = "5"#var.min_cpu_threshold
#   dimensions = {
#     ClusterName = var.cluster_name
#     ServiceName = aws_ecs_service.service.name
#   }
#   alarm_actions = [aws_appautoscaling_policy.scale_down_policy.arn]

#   #tags = var.tags
# }

# ------------------------------------------------------------------------------
# AWS Auto Scaling - Scaling Up Policy
# ------------------------------------------------------------------------------
resource "aws_appautoscaling_policy" "scale_up_policy" {
  name               = "${var.service_full_name}-scale-up-policy"
  depends_on         = [aws_appautoscaling_target.scale_target]

  resource_id        = aws_appautoscaling_target.scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.scale_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.scale_target.service_namespace
  
  step_scaling_policy_configuration {
    
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 30
    metric_aggregation_type = "Maximum"
    
    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

# ------------------------------------------------------------------------------
# AWS Auto Scaling - Scaling Down Policy
# ------------------------------------------------------------------------------
resource "aws_appautoscaling_policy" "scale_down_policy" {
  name               = "${var.service_full_name}-scale-down-policy"
  depends_on         = [aws_appautoscaling_target.scale_target]
  
  resource_id        = aws_appautoscaling_target.scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.scale_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.scale_target.service_namespace
  
  step_scaling_policy_configuration {
    
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 30
    metric_aggregation_type = "Maximum"
    
    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

#------------------------------------------------------------------------------
# AWS Auto Scaling - Scaling Target
#------------------------------------------------------------------------------
resource "aws_appautoscaling_target" "scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.ecs_min_size
  max_capacity       = var.ecs_max_size
}
