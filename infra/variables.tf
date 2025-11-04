variable "project_name" {
  type    = string
  default = "rails-ecs"
}

variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type = list(string)
  default = [
    "10.0.11.0/24",
    "10.0.12.0/24",
  ]
}

# Container config (The port the application listens on, confirmed to be 3000)
variable "container_port" {
  type    = number
  default = 3000
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "cpu" {
  type    = number
  default = 256
}

variable "memory" {
  type    = number
  default = 512
}

# Image tag pushed by CI later.
variable "image_tag" {
  type    = string
  default = "latest"
}

# Secrets/Env via SSM (used by ssm.tf)
variable "rails_env" {
  type    = string
  default = "production"
}

variable "secret_key_base" {
  type    = string
  default = "a-placeholder-secret-for-rails"
}

variable "rails_master_key" {
  type    = string
  default = "a-placeholder-master-key"
}
