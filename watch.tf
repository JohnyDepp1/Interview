resource "aws_cloudwatch_metric_alarm" "metric_alarm" {
  alarm_name                = "CPU_Util"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "60"
  alarm_description         = "Metric to monitor EC2 cpu utilization above 60%"
  insufficient_data_actions = []
}