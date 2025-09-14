
output "aws_account_id" {
  description = "AWS ACCOUNT ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_account_alias" {
  description = "AWS ACCOUNT ALIAS"
  value       = data.aws_iam_account_alias.current.account_alias
}

output "ecr_repository_url" {
  description = "ECR REPO URL"
  value       = aws_ecr_repository.custom-app.repository_url
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${var.region} update-kubeconfig --name ${module.eks-cluster.cluster_name} --profile lcrosa"
}
