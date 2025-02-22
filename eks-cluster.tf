provider "kubernetes" {
    load_config_file = "false"
    host = data.aws_eks_cluster.myapp-cluster.endpoint
    token = data.aws_eks_cluster_auth.myapp-cluster.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.myapp-cluster.certificate_authority.0.data)

}

data "aws_eks_cluster" "myapp-cluster" {
    name = module.eks.cluster_name
    
  
}
data "aws_eks_cluster_auth" "myapp-cluster" {
    name = module.eks.cluster_name
  
}
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.33.1"

  cluster_name = "myapp-eks-cluster"
  cluster_version = "1.32"

  subnet_ids = module.myapp-vpc.private_subnets

  vpc_id = module.myapp-vpc.vpc_id
  
  tags = {
    #custom tags
    enviroment = "development"
    application = "myapp"
    owner = "victor"
  }

  self_managed_node_groups = {
    example = {
        instance_type = "t2.micro"
        desired_size = 2
    }
    
  }

}