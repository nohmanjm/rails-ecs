# [Image of an electronic circuit board]
output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.rails_ecs_alb.dns_name
}

output "ecr_repo_url" {
  description = "The full URL of the ECR repository"
  value       = aws_ecr_repository.rails_ecs_repo.repository_url
}
