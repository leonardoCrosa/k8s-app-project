# This configuration allows Github Actions to interact with AWS Resources

# Setting Github as an AWS OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]
}
# This datasource builds the trust policy that allows gh actions to assume the role
data "aws_iam_policy_document" "gha_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = "repo:leonardoCrosa/k8s-app-project:ref:refs/heads/master"
    }
  }
}
# IAM Role with trust policy gha_trust attached
resource "aws_iam_role" "gha" {
  name               = "gha-eks-k8s-app-project"
  assume_role_policy = data.aws_iam_policy_document.gha_trust.json
}

# Minimal IAM Policy json. GH Actions only needs to see cluster name and then it will access it via access entry
data "aws_iam_policy_document" "eks_describe" {
  statement {
    actions   = ["eks:DescribeCluster"]
    resources = ["*"]
  }
}
# The minimal policy that will give gha permissions via assumerole
resource "aws_iam_policy" "eks_describe" {
  name   = "eks-describecluster-min"
  policy = data.aws_iam_policy_document.eks_describe.json
}
# Attaching the eks_describe policy to our role
resource "aws_iam_role_policy_attachment" "gha_eks_describe" {
  role       = aws_iam_role.gha.name
  policy_arn = aws_iam_policy.eks_describe.arn
}
# Create the access entry that will grant the gha runner permissions inside my EKS Cluster
resource "aws_eks_access_entry" "eks-gha-entry" {
  cluster_name  = module.eks-cluster.cluster_name
  principal_arn = aws_iam_role.gha.arn
}
# Define gha runner as cluster admin
resource "aws_eks_access_policy_association" "gha_admin" {
  cluster_name  = module.eks-cluster.cluster_name
  principal_arn = aws_iam_role.gha.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope { type = "cluster" }
}
# Load the generated Role's ARN into a gha variable
resource "github_actions_variable" "aws_role_arn" {
  repository    = "k8s-app-project"
  variable_name = "AWS_ROLE_ARN"
  value         = aws_iam_role.gha.arn
}
