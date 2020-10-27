output "vpc" {
    value = module.vpc
}

output "sg" {
    value = {
        bastion = module.bastion_sg.this_security_group_id
        app = aws_security_group.app_sg.id
    }
}

output "alb" {
    value = module.alb
}