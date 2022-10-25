data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "auth" {
  name = var.eks_cluster_name
}

provider "kubernetes" {
  host = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token = data.aws_eks_cluster_auth.auth.token
}

provider "helm" {
  kubernetes {
    host = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token = data.aws_eks_cluster_auth.auth.token
  }
}
