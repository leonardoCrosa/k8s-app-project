# Configure the AWS Provider
provider "aws" {
  region  = var.region
  profile = "lcrosa"
}

# Configure the k8s Provider for the eks cluster using the token gathered from the datasource
#provider "kubernetes" {
#  host                   = module.eks-cluster.cluster_endpoint
#  cluster_ca_certificate = base64decode(module.eks-cluster.cluster_certificate_authority_data)
#  token                  = data.aws_eks_cluster_auth.this.token
#}

# Configure the helm Provider in the same way as the k8s Provider
# The embedded kubernetes block makes helm use the same eks access token as the k8s provider
provider "helm" {
  kubernetes = {
    host                   = module.eks-cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks-cluster.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

provider "github" {
  owner = "leonardocrosa"
}
