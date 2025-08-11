# For outputting the current tf working aws account id
data "aws_caller_identity" "current" {}
# For outputting the current tf working aws account alias
data "aws_iam_account_alias" "current" {}

# Give terraform access to the EKS cluster via the kubernetes and helm providers
data "aws_eks_cluster_auth" "this" {
  name = module.eks-cluster.cluster_name
}
