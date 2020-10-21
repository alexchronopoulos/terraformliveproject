provider "aws" {
    version = "2.65.0"
    region = var.region
}

module "vpc" {
    source = "./modules/vpc"
    namespace = var.namespace
    ssh_public_ip = var.ssh_public_ip
}

module "ec2" {
    source = "./modules/ec2"
    namespace = var.namespace
    vpc = module.vpc.vpc
    sg = module.vpc.sg
    ssh_keypair = var.ssh_keypair
}

module "ecs" {
    source = "./modules/ecs"
    namespace = var.namespace
    alb = module.ec2.alb
    iam_role_arns = module.iam.iam_role_arns
    sg = module.vpc.sg
    vpc = module.vpc.vpc
}

module "iam" {
    source = "./modules/iam"
}