#----------Setting up CLoaudwatch alarm to monitor cpu utilization f the instances in the autoscaling group -------------------


resource "aws_cloudwatch_metric_alarm" "alarm" {
  alarm_name          = "CPUUTILIZATION_ALARM_AG"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/AutoScaling"
  period              = 120
  statistic           = "Average"
  threshold           = 50

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.AG.name

  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_sns_topic.cpualarm.arn]
}

resource "aws_sns_topic" "cpualarm" {
  name = "CPU_UTILIZATION_GREATER_THAN_THRESHOLD"
}

resource "aws_sns_topic_subscription" "subscription3" {
  topic_arn = aws_sns_topic.cpualarm.arn
  protocol  = "email"
  endpoint  = "azeezsolola@gmail.com"   
}

resource "aws_sns_topic_subscription" "subscription4" {
  topic_arn = aws_sns_topic.cpualarm.arn
  protocol  = "email"
  endpoint  = "michael.ojejinmi@stackitsolutions.com"   
}


#------------------Creating cloudwatch alarm for RDS cpu utilization ------------------------------------------
resource "aws_cloudwatch_metric_alarm" "alarm2" {
  alarm_name          = "CPUUTILIZATION_ALARM_RDS"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 120
  statistic           = "Average"
  threshold           = 50

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.restored_db.identifier

  }

  alarm_description = "This metric monitors rds cpu utilization"
  alarm_actions     = [aws_sns_topic.cpualarm1.arn]
}

resource "aws_sns_topic" "cpualarm1" {
  name = "CPU_UTILIZATION_GREATER_THAN_THRESHOLD_RDSDATABASE"
}

resource "aws_sns_topic_subscription" "subscription5" {
  topic_arn = aws_sns_topic.cpualarm.arn
  protocol  = "email"
  endpoint  = "azeezsolola@gmail.com"   
}

resource "aws_sns_topic_subscription" "subscription6" {
  topic_arn = aws_sns_topic.cpualarm.arn
  protocol  = "email"
  endpoint  = "michael.ojejinmi@stackitsolutions.com"   
}