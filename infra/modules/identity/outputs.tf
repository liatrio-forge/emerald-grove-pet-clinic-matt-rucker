output "ci_role_arn" {
  description = "ARN of the CI role (for GitHub Actions to assume via OIDC)"
  value       = aws_iam_role.ci.arn
}

output "tofu_role_arn" {
  description = "ARN of the Tofu role (for infrastructure management)"
  value       = aws_iam_role.tofu.arn
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider"
  value       = data.aws_iam_openid_connect_provider.github.arn
}
