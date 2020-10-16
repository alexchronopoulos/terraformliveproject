data "aws_ami" "amazonlinux" {
    most_recent = true
    filter {
        name = "name"
        values = ["amzn2-ami-hvm-2.0.*"]
    }
    owners = ["137112412989"]
}

resource "aws_launch_template" "app" {
    name_prefix = var.namespace
    image_id = data.aws_ami.amazonlinux.id
    instance_type = "t2.micro"
    key_name = var.ssh_keypair
    vpc_security_group_ids = [var.sg.app]
}

resource "aws_launch_template" "bastion" {
    name_prefix = var.namespace
    image_id = data.aws_ami.amazonlinux.id
    instance_type = "t2.micro"
    key_name = var.ssh_keypair
    vpc_security_group_ids = [var.sg.bastion]
}

resource "aws_autoscaling_group" "app" {
    name = "${var.namespace}-app-asg"
    min_size = 1
    max_size = 3
    vpc_zone_identifier = var.vpc.private_subnets
    launch_template {
        id = aws_launch_template.app.id
        version = aws_launch_template.app.latest_version
    }
}

resource "aws_autoscaling_group" "bastion" {
    name = "${var.namespace}-bastion-asg"
    min_size = 1
    max_size = 3
    vpc_zone_identifier = var.vpc.public_subnets
    launch_template {
        id = aws_launch_template.bastion.id
        version = aws_launch_template.bastion.latest_version
    }
}