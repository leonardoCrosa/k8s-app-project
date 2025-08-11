# This variable is used in the eks-access.tf file to define access to the eks cluster
variable "eks-admins" {
  description = "IAM role/user ARNs that should have cluster-admin"
  type        = list(string)
}

