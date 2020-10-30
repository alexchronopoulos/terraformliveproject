output "alb_dns_name" {
    value = module.networking.alb.this_lb_dns_name
}

output "codecommit_repo_url" {
    value = module.codepipeline.repo_url
}

output "ecr_repo_url" {
    value = module.compute.ecr_repo.registry_url
}