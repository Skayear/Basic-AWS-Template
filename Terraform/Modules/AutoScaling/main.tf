resource "tls_private_key" "key_gen" {  
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_s3_bucket_object" "private_key" {  
  bucket  = var.ssh_bucket
  key     = var.env_full_name
  content = tls_private_key.key_gen.private_key_openssh
}

resource "aws_key_pair" "key" {  
  key_name   = "${var.env_full_name}-key"
  public_key = tls_private_key.key_gen.public_key_openssh
}

resource "aws_autoscaling_group" "ec2_group" { 
  name                      = "${var.env_full_name}-as-group"
  vpc_zone_identifier       = var.subnet_ids

  min_size                  = var.ec2_min_size
  max_size                  = var.ec2_max_size
  desired_capacity          = var.ec2_desired_capacity
  health_check_grace_period = 0
  launch_configuration      = aws_launch_configuration.ec_instance.name

  termination_policies = ["NewestInstance"]

  enabled_metrics = [
    "GroupAndWarmPoolDesiredCapacity",
    "GroupAndWarmPoolTotalCapacity",
    "GroupDesiredCapacity",
    "GroupInServiceCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingCapacity",
    "GroupPendingInstances",
    "GroupStandbyCapacity",
    "GroupStandbyInstances",
    "GroupTerminatingCapacity",
    "GroupTerminatingInstances",
    "GroupTotalCapacity",
    "GroupTotalInstances",
    "WarmPoolDesiredCapacity",
    "WarmPoolMinSize",
    "WarmPoolPendingCapacity",
    "WarmPoolTerminatingCapacity",
    "WarmPoolTotalCapacity",
    "WarmPoolWarmedCapacity"
  ]

  lifecycle {
        ignore_changes = [ desired_capacity ]
  }

  tag {
    key                 = "Name"
    value               = "${var.env_full_name}-ec2"
    propagate_at_launch = true
  }
}
 
resource "aws_autoscaling_policy" "increase_count" {
  name                   = "${var.env_full_name}-as-increase-policy"
  scaling_adjustment     = var.autoscaling_count_variation_up
  adjustment_type        = "ChangeInCapacity" 
  autoscaling_group_name = aws_autoscaling_group.ec2_group.name 
  cooldown               = 120
}
 
resource "aws_cloudwatch_metric_alarm" "service_cpu_high" {
  alarm_name          = "${var.env_full_name}_cpu_utilization_HIGH"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "65"

  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.ec2_group.name}"
  }

  alarm_actions     = [aws_autoscaling_policy.increase_count.arn]
}

resource "aws_cloudwatch_metric_alarm" "service_memory_high" {
  alarm_name = "${var.env_full_name}-memory-alarm-HIGH"
  alarm_description = "memory-alarm-HIGH"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "3"
  metric_name = "mem_used_percent"
  namespace = "CWAgent"
  period = "60"
  statistic = "Maximum"
  threshold = "65"
  
  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.ec2_group.name}"
  }

  actions_enabled = true
  alarm_actions = [aws_autoscaling_policy.increase_count.arn]
}

resource "aws_cloudwatch_metric_alarm" "service_reservation_cpu_high" {
  alarm_name          = "${var.env_full_name}_cpu_reservation_HIGH"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUReservation"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "85"

  dimensions = {
    "ClusterName" = "${var.cluster_name}"
  }

 alarm_actions     = [aws_autoscaling_policy.increase_count.arn]
}

resource "aws_cloudwatch_metric_alarm" "service_reservation_memory_high" {
  alarm_name          = "${var.env_full_name}_memory_reservation_HIGH"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "MemoryReservation"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "85"

  dimensions = {
    "ClusterName" = "${var.cluster_name}"
  }

  alarm_actions     = [aws_autoscaling_policy.increase_count.arn]
}
 
resource "aws_autoscaling_policy" "decrease_count" {
  name                   = "${var.env_full_name}-as-decrease-policy"
  scaling_adjustment     = var.autoscaling_count_variation_down
  adjustment_type        = "ChangeInCapacity" 
  autoscaling_group_name = aws_autoscaling_group.ec2_group.name
  cooldown               = 300
}
 
resource "aws_cloudwatch_metric_alarm" "service_cpu_low" {
  alarm_name          = "${var.env_full_name}_cpu_utilization_LOW"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Minimum"
  threshold           = "10"

  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.ec2_group.name}"
  }

  alarm_actions     = [aws_autoscaling_policy.decrease_count.arn]
}

resource "aws_cloudwatch_metric_alarm" "service_memory_low" {
  alarm_name = "${var.env_full_name}-memory-alarm-LOW"
  alarm_description = "memory-alarm-HIGH"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "3"
  metric_name = "mem_used_percent"
  namespace = "CWAgent"
  period = "120"
  statistic = "Minimum"
  threshold = "10"
  
  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.ec2_group.name}"
  }

  actions_enabled = true
  alarm_actions = [aws_autoscaling_policy.decrease_count.arn]
}

resource "aws_cloudwatch_metric_alarm" "service_reservation_cpu_low" {
  alarm_name          = "${var.env_full_name}_cpu_reservation_LOW"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUReservation"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Minimum"
  threshold           = "30"

  dimensions = {
    "ClusterName" = "${var.cluster_name}"
  }

 alarm_actions     = [aws_autoscaling_policy.decrease_count.arn]
}



resource "aws_cloudwatch_metric_alarm" "service_reservation_memory_low" {
  alarm_name          = "${var.env_full_name}_memory_reservation_LOW"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "MemoryReservation"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Minimum"
  threshold           = "30"

  dimensions = {
    "ClusterName" = "${var.cluster_name}"
  }

 alarm_actions     = [aws_autoscaling_policy.decrease_count.arn]
}

 
////////////Cloudwatch agent
# data "aws_iam_policy" "CloudWatchAgentServerPolicy"{
#   name="CloudWatchAgentServerPolicy"
# }
resource "aws_iam_role_policy_attachment" "my_policy_attachment" {
  role       = "${aws_iam_role.ec2_instance_role.name}"
  policy_arn = "${data.aws_iam_policy.CloudWatchAgentServerPolicy.arn}"
}
/////////

resource "aws_iam_instance_profile" "ec2_instance_profile" { 
  name = "${var.env_full_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
}
 
resource "aws_iam_role" "ec2_instance_role" { 
  name               = "${var.env_full_name}-ec2-instance"
  assume_role_policy = templatefile("${path.module}/policies/instance-role-trust-policy.json",{ecs_cluster_name   = var.cluster_name })
}

resource "aws_iam_role_policy" "ec2_instance_role_policy" { 
  name   = "${var.env_full_name}-ec2-instance-role"
  role   = aws_iam_role.ec2_instance_role.name
  policy = templatefile("${path.module}/policies/instance-profile-policy.json",{ecs_cluster_name   = var.cluster_name })
}

resource "aws_launch_configuration" "ec_instance" { 
  security_groups      = concat([aws_security_group.ec2_security_group.id], [var.aux_access_sg])
  key_name             = aws_key_pair.key.key_name
  image_id             = var.ec2_image_id
  instance_type        = var.ec2_instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  user_data            = "${templatefile("${path.module}/user_data/amzl-user-data.tpl", {  
    ecs_cluster_name   = "${var.cluster_name}"
    AutoScalingGroupName = "$${aws:AutoScalingGroupName}"
    ImageId = "$${aws:ImageId}"
    InstanceId = "$${aws:InstanceId}"
    InstanceType = "$${aws:InstanceType}" 
    })
  }"

  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = 50 
  }

  depends_on = [aws_security_group.ec2_security_group]
}

resource "aws_security_group" "ec2_security_group" { 
  name = "${var.env_full_name}-sg"
  description = "Security group for ec2"
  vpc_id = var.vpc_id

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "ssh access group"
    from_port = 22      
    to_port = 22
    protocol = "tcp"  
  }

   ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "dynamic port access group"
    from_port = 32768
    to_port = 65535
    protocol = "tcp"
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]    
  }

}


/*
resource "aws_autoscaling_policy" "increase_count" {
  name                   =  "${var.env_full_name}-as-increase-policy"
  scaling_adjustment     = var.autoscaling_count_variation_up
  adjustment_type        = "ChangeInCapacity" 
  autoscaling_group_name = aws_autoscaling_group.ec2_group.name 
  cooldown = 120
}
resource "aws_autoscaling_policy" "decrease_count" {
  name                   = "${var.env_full_name}-as-decrease-policy"
  scaling_adjustment     = var.autoscaling_count_variation_down
  adjustment_type        = "ChangeInCapacity" 
  autoscaling_group_name = aws_autoscaling_group.ecs_group.name
  cooldown = 120
}

resource "aws_cloudwatch_metric_alarm" "service_reservation_cpu_high" {
  alarm_name          = "${var.env_full_name}_cpu_reservation_HIGH"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUReservation"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "60"

  dimensions = {
    "ClusterName" = "${aws_ecs_cluster.cluster.name}"
  }

 alarm_actions     = [aws_autoscaling_policy.increase_count.arn]
}


resource "aws_cloudwatch_metric_alarm" "service_reservation_cpu_low" {
  alarm_name          = "${var.env_full_name}_cpu_reservation_LOW"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "5"
  metric_name         = "CPUReservation"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "10"

  dimensions = {
    "ClusterName" = "${aws_ecs_cluster.cluster.name}"
  }

 alarm_actions     = [aws_autoscaling_policy.decrease_count.arn]
}*/
