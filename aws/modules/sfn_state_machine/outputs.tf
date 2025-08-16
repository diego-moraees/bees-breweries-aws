output "state_machine_arn" {
  value = aws_sfn_state_machine.this.arn
}
output "state_machine_name" {
  value = aws_sfn_state_machine.this.name
}
output "role_arn" {
  value = aws_iam_role.sfn_role.arn
}
