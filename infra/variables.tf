# This variable is used in the eks-access.tf file to define access to the eks cluster
variable "eks-admins" {
  description = "IAM role/user ARNs that should have cluster-admin"
  type        = list(string)
}
# LBC Helm Chart version to be called from eks-lb.tf
variable "helm-lbc-package-version" {
  description = "AWS Load Balancer Controller Helm Chart Version"
  default     = "1.13.4"
  type        = string
}
