resource "aws_iam_role" "task_role" {
  name = "wishifai-task-role-kandidat${var.kandidatnummer}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "task_policy" {
  role = aws_iam_role.task_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = "rekognition:DetectLabels", Resource = "*" },
      { Effect = "Allow", Action = "bedrock:InvokeModel", Resource = "*" },
      { Effect = "Allow", Action = "s3:PutObject", Resource = "${aws_s3_bucket.images.arn}/*" },
      { Effect = "Allow", Action = "cloudwatch:PutMetricData", Resource = "*" }
    ]
  })
}