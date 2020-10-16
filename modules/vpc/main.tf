data "aws_availability_zones" "available" {}

module "vpc" {
    source                           = "terraform-aws-modules/vpc/aws"
    version                          = "2.5.0"
    name                             = "${var.namespace}-vpc"
    cidr                             = "172.16.0.0/16"
    azs                              = data.aws_availability_zones.available.names
    private_subnets                  = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]
    public_subnets                   = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
    database_subnets                 = ["172.16.8.0/24", "172.16.9.0/24", "172.16.10.0/24"]
    assign_generated_ipv6_cidr_block = true
    create_database_subnet_group     = true
    enable_nat_gateway               = true
    single_nat_gateway               = true
}

module "bastion_sg" {
    source = "terraform-aws-modules/security-group/aws//modules/ssh"

    name = "bastion"
    description = "Security group for bastion hosts with SSH open from specific IP"
    vpc_id = module.vpc.vpc_id

    ingress_cidr_blocks = ["${var.ssh_public_ip}"]
}

resource "aws_security_group" "app_sg" {
    name = "app_sg"
    description = "Allow SSH from bastion_sg"
    vpc_id = module.vpc.vpc_id

    ingress {
        description = "SSH from bastion_sg"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        security_groups = ["${module.bastion_sg.this_security_group_id}"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}