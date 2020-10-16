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