output "alb_dns_name" {
    value = module.ec2.alb.this_lb_dns_name
}

output "repo_url" {
    value = module.codepipeline.repo_url
}