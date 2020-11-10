provider "aws" {
    version = "2.65.0"
    region = var.region
}

module "networking" {
    source = "./modules/networking"
    namespace = var.namespace
    ssh_public_ip = var.ssh_public_ip
    port = var.port
}

module "compute" {
    source = "./modules/compute"
    namespace = var.namespace
    vpc = module.networking.vpc
    sg = module.networking.sg
    ssh_keypair = var.ssh_keypair
    bastion_hosts = var.bastion_hosts
    alb = module.networking.alb
    task = var.task
    port = var.port
}

module "codepipeline" {
    source = "./modules/codepipeline"
    namespace = var.namespace
    branch = var.branch
    task = var.task
    ecs_cluster = module.compute.ecs_cluster
    ecs_service = module.compute.ecs_service
    alb = module.networking.alb
}

module "database" {
    source = "./modules/database"
    namespace = var.namespace
    region = var.region
    destRegion = var.destRegion
    sourceFileName = var.sourceFileName
    backupFileName = var.backupFileName
}
