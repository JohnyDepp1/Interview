#alarm for monitoring of the  CPU usage of each 
resource "aws_cloudwatch_metric_alarm" "metric_alarm" {
#name for the alarm
  alarm_name                = "CPU_Util"
#one of the comparison operator in the aws collection
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  #the metric to for the cloudwatch to observe
  metric_name               = "CPUUtilization"
  #one of the predefines namespaces. 
  #currently to watch for CPU Util. on an EC2 instance
  namespace                 = "AWS/EC2"
  #how often to check
  period                    = "120"
  #The average use of CPU
  statistic                 = "Average"
  threshold                 = "60"
  alarm_description         = "Metric and alarm to monitor EC2 cpu utilization above 60%"
  insufficient_data_actions = []
}