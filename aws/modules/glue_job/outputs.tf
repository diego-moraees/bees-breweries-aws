output "job_name" {
  description = "Glue job name"
  value       = aws_glue_job.this.name
}

output "job_arn" {
  description = "Glue job ARN"
  value       = aws_glue_job.this.arn
}
