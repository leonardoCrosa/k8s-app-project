resource "aws_eks_access_entry" "eks-admins-entry" {
  for_each      = toset(var.eks-admins)
  cluster_name  = module.eks-cluster.cluster_name
  principal_arn = each.value
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admins_admin" {
  for_each      = aws_eks_access_entry.eks-admins-entry
  cluster_name  = module.eks-cluster.cluster_name
  principal_arn = each.value.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope { type = "cluster" }
}
