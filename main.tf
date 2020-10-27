provider "aws" {
    version = "2.65.0"
    region = var.region
}

module "networking" {
    source = "./modules/networking"
    namespace = var.namespace
    ssh_public_ip = var.ssh_public_ip
}

module "compute" {
    source = "./modules/compute"
    namespace = var.namespace
    vpc = module.networking.networking
    sg = module.networking.sg
    ssh_keypair = var.ssh_keypair
    bastion_hosts = var.bastion_hosts
    alb = module.networking.alb
    task = var.task
}

module "codepipeline" {
    source = "./modules/codepipeline"
    namespace = var.namespace
    branch = var.branch
    task = var.task
}
