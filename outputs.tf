output "alb_dns_name" {
    value = module.networking.alb.this_lb_dns_name
}

output "repo_url" {
    value = module.codepipeline.repo_url
}