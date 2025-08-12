locals {
  cluster_name       = "k8s-app-project"
  kubernetes_version = "1.33"
}

module "eks-cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.cluster_name
  kubernetes_version = local.kubernetes_version

  # EKS Addons
  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    node-group = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      instance_types = ["t3.small"]
      ami_type       = "AL2023_x86_64_STANDARD"

      min_size = 2
      max_size = 3
      # This value is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack
      desired_size = 2
      # Uses my current public ip data source to add it as allowed public access
      cluster_endpoint_public_access       = true
      cluster_endpoint_public_access_cidrs = ["${data.external.myip.result.ip}/32"]
    }
  }
}
