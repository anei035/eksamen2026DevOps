output "service_url" {
  value = aws_ecs_express_gateway_service.app.ingress_paths[0].endpoint
}

output "service_name" {
  value = aws_ecs_express_gateway_service.app.service_name
}

output "bucket_name" {
  value = aws_s3_bucket.images.bucket
}