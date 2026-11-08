resource "aws_cloudwatch_metric_alarm" "bedrock_latency" {
  alarm_name  = "kandidat${var.kandidatnummer}-bedrock-latency"
  namespace   = "kandidat${var.kandidatnummer}"
  metric_name = "bedrock_latency.avg"

  dimensions = {
    class     = "no.pgr301.exam.service.BedrockService"
    method    = "suggestGifts"
    exception = "none"
  }

  comparison_operator = "GreaterThanThreshold"
  threshold           = 20000
  evaluation_periods  = 2
  period              = 60
  statistic           = "Average"

  alarm_description = "Går av når gjennomsnittlig responstid for Bedrock er over 20 sekunder"
  alarm_actions     = [aws_sns_topic.alarm.arn]
}

resource "aws_sns_topic" "alarm" {
  name = "kandidat${var.kandidatnummer}-alarm-topic"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarm.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}