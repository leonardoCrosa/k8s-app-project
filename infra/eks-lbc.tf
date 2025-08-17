# Trust policy document that allows aws LBC's service account to assume a role
data "aws_iam_policy_document" "lbc_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [module.eks-cluster.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks-cluster.cluster_oidc_issuer_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks-cluster.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}
# The role for LBC to assume
resource "aws_iam_role" "lbc" {
  name               = "AmazonEKSLoadBalancerControllerRole"
  assume_role_policy = data.aws_iam_policy_document.lbc_assume.json
}
# The policy with the permissions the LBC will have when assuming the role
resource "aws_iam_policy" "lbc" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = file("${path.module}/policies/aws-load-balancer-controller.json")
}
# Attaches the previous IAM Policy to the IAM Role
resource "aws_iam_role_policy_attachment" "lbc_attach" {
  role       = aws_iam_role.lbc.name
  policy_arn = aws_iam_policy.lbc.arn
}


## Helm install for AWS Load Balancer Ingress Controller Helm Package

resource "helm_release" "aws_load_balancer_controller" {
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  namespace        = "kube-system"
  create_namespace = false
  timeout          = 600
  atomic           = true

  version = var.helm-lbc-package-version

  # Configure values for helm package
  # Creates a Service Account for LBC controller in my EKS cluster
  values = [yamlencode({
    clusterName = module.eks-cluster.cluster_name
    region      = var.region
    vpcId       = module.vpc.vpc_id
    serviceAccount = {
      create = true
      name   = "aws-load-balancer-controller"
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.lbc.arn
      }
    }
  })]

  depends_on = [
    aws_iam_role_policy_attachment.lbc_attach,     # IAM Role and Policy need to be attached before creating SA account
    module.eks-cluster,                            # Cluster needs to be ready for helm to access it
    aws_eks_access_policy_association.admins_admin # Terraform user needs to exist for helm to work
  ]
}
