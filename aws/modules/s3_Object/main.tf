resource "aws_s3_object" "object" {
  bucket = var.bucket_id
  key    = "${var.remote_path}/${basename(var.local_path)}"
  source = abspath("${path.module}/${var.local_path}")
  etag   = filemd5(abspath("${path.module}/${var.local_path}"))
  acl    = "private"
}