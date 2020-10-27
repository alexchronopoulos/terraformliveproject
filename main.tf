provider "aws" {
    version = "2.65.0"
    region = var.region
}

module "networking" {
    source = "./modules/networking"
    namespace = var.namespace
    ssh_public_ip = var.ssh_public_ip
}

module "ec2" {
    source = "./modules/ec2"
    namespace = var.namespace
    networking = module.networking.networking
    sg = module.networking.sg
    ssh_keypair = var.ssh_keypair
    bastion_hosts = var.bastion_hosts
}

module "ecs" {
    source = "./modules/ecs"
    namespace = var.namespace
    alb = module.networking.alb
    sg = module.networking.sg
    networking = module.networking.networking
    task = var.task
}

module "codepipeline" {
    source = "./modules/codepipeline"
    namespace = var.namespace
    branch = var.branch
    task = var.task
}
