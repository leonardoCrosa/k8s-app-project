# For outputting the current tf working aws account id
data "aws_caller_identity" "current" {}
# For outputting the current tf working aws account alias
data "aws_iam_account_alias" "current" {}

# Give terraform access to the EKS cluster via the kubernetes and helm providers
data "aws_eks_cluster_auth" "this" {
  name = module.eks-cluster.cluster_name
}
# This data runs a command on my terminal to get my current public ip so that it can add it every time as public access to the EKS cluster, allowing me to use kubectl every time I redeploy the cluster.
data "external" "myip" {
  program = ["bash", "-c", "echo '{\"ip\": \"'$(curl -s https://checkip.amazonaws.com | tr -d '\n')'\"}'"]
}
