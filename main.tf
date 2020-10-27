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
    bastion_hosts = var.bastion_hosts
}

module "ecs" {
    source = "./modules/ecs"
    namespace = var.namespace
    alb = module.ec2.alb
    sg = module.vpc.sg
    vpc = module.vpc.vpc
    task = var.task
}

module "codepipeline" {
    source = "./modules/codepipeline"
    namespace = var.namespace
    branch = var.branch
    task = var.task
}
