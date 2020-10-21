data "aws_ami" "amazonlinux" {
    most_recent = true
    filter {
        name = "name"
        values = ["amzn2-ami-hvm-2.0.*"]
    }
    owners = ["137112412989"]
}

resource "aws_launch_template" "bastion" {
    name_prefix = var.namespace
    image_id = data.aws_ami.amazonlinux.id
    instance_type = "t2.micro"
    key_name = var.ssh_keypair
    vpc_security_group_ids = [var.sg.bastion]
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

module "alb" {
    source = "terraform-aws-modules/alb/aws"
    version = "~> v5.0"

    name = "${var.namespace}-alb"

    load_balancer_type = "application"
    vpc_id = var.vpc.vpc_id
    subnets = var.vpc.public_subnets
    security_groups = [var.sg.lb]
    
    target_groups = [
        { 
            name = "app"
            backend_protocol = "HTTP"
            backend_port = 5000
            target_type = "ip"
            health_check = {
                enabled             = true
                interval            = 30
                path                = "/"
                port                = "traffic-port"
                healthy_threshold   = 3
                unhealthy_threshold = 3
                timeout             = 6
                protocol            = "HTTP"
                matcher             = "200-399"
            } 
        }
    ]
    http_tcp_listeners  = [
        { 
            port = 80
            protocol = "HTTP"
        }
    ]

}