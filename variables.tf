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