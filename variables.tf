variable "namespace" {
    type = string
}

variable "region" {
    type = string
}

variable "ssh_public_ip" {
    type = string
}

variable "ssh_keypair" {
    description = "ssh public key to use for bastion EC2 instances"
    default = "koffeeluv"
    type = string
}

variable "bastion_hosts" {
    description = "Number of bastion hosts to create"
    default = 0
    type = number
}

variable "task" {
    description = "name of the application being run"
    default = "flask"
    type = string
}

variable "branch" {
    description = "branch where codepipeline will look for changes"
    default = "master"
    type = string
}

variable "port" {
    description = "port the container application runs on"
    default = 5000
    type = number
}

variable "destRegion" {
    description = "Destination region for cross-region replication of database backup"
    default = "us-west-2"
    type = string
}