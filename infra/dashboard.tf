resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "kandidat${var.kandidatnummer}-wishifai"
  dashboard_body = <<DASHBOARD
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "kandidat${var.kandidatnummer}", "gift_suggestions.count" ]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "${var.region}",
        "title": "Antall gaveforslag generert"
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "kandidat${var.kandidatnummer}", "bedrock_latency.avg", "class", "no.pgr301.exam.service.BedrockService", "method", "suggestGifts", "exception", "none" ],
          [ "kandidat${var.kandidatnummer}", "rekognition_latency.avg", "class", "no.pgr301.exam.service.RekognitionService", "method", "detectLabels", "exception", "none" ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "${var.region}",
        "title": "Responstid Bedrock og Rekognition (ms)"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 6,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/ECS", "CPUUtilization", "ServiceName", "${aws_ecs_express_gateway_service.app.service_name}", "ClusterName", "default" ],
          [ "AWS/ECS", "MemoryUtilization", "ServiceName", "${aws_ecs_express_gateway_service.app.service_name}", "ClusterName", "default" ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "${var.region}",
        "title": "ECS CPU og minnebruk (%)"
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 6,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "kandidat${var.kandidatnummer}", "http.server.requests.avg", "uri", "/api/analyze", "method", "POST", "status", "200", "outcome", "SUCCESS", "exception", "none", "error", "none" ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "${var.region}",
        "title": "HTTP responstid /api/analyze (ms)"
      }
    }
  ]
}
DASHBOARD
}