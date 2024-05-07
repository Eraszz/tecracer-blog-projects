################################################################################
# Autoscaling Group
################################################################################

resource "aws_autoscaling_group" "this" {
  name = var.application_name

  max_size         = 3
  min_size         = 1
  desired_capacity = 1

  vpc_zone_identifier  = local.private_subnet_ids
  target_group_arns    = [aws_lb_target_group.this.arn]
  termination_policies = ["OldestInstance"]

  health_check_grace_period = 300
  health_check_type         = "ELB"

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }
}

resource "aws_autoscaling_attachment" "this" {
  autoscaling_group_name = aws_autoscaling_group.this.id
  lb_target_group_arn    = aws_lb_target_group.this.arn
}


################################################################################
# SCALE DOWN Autoscaling Policy
################################################################################

resource "aws_autoscaling_policy" "scale_down" {
  name                   = format("%s-%s", var.application_name, "scale-down")
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 120
  autoscaling_group_name = aws_autoscaling_group.this.name
}

resource "aws_cloudwatch_metric_alarm" "scale_down" {

  alarm_description   = "Monitors CPU utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
  alarm_name          = format("%s-%s", var.application_name, "scale-down")
  comparison_operator = "LessThanOrEqualToThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = "25"
  evaluation_periods  = "5"
  period              = "30"
  statistic           = "Average"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }
}


################################################################################
# SCALE UP Autoscaling Policy
################################################################################

resource "aws_autoscaling_policy" "scale_up" {
  name                   = format("%s-%s", var.application_name, "scale-up")
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 120
  autoscaling_group_name = aws_autoscaling_group.this.name
}

resource "aws_cloudwatch_metric_alarm" "scale_up" {

  alarm_description   = "Monitors CPU utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  alarm_name          = format("%s-%s", var.application_name, "scale-up")
  comparison_operator = "GreaterThanOrEqualToThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = "90"
  evaluation_periods  = "5"
  period              = "30"
  statistic           = "Average"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }
}

