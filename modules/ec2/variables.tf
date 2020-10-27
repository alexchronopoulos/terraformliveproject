variable "namespace" {
    type = string
}

variable "vpc" {
    type = any
}

variable "sg" {
    type = any
}

variable "ssh_keypair" {
    type = string
}

variable "bastion_hosts" {
    type = number
}