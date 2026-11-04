resource "aws_s3_bucket" "images" {
  bucket = "kandidat${var.kandidatnummer}-wishifai-images"
}