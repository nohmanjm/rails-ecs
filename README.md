AWS ECS Fargate Deployment for Ruby API via Terraform & GitHub Actions

This project is a complete, end-to-end demonstration of a modern CI/CD pipeline. It deploys a containerized Ruby (Sinatra) application to AWS ECS Fargate, provisioned entirely with Terraform, and automated with GitHub Actions using OIDC for secure authentication.

The primary objective is to demonstrate a secure, automated, and idempotent infrastructure-as-code (IaC) deployment.

🏛️ Architecture

The infrastructure is designed for high availability and security:

VPC: A custom VPC with two public subnets across two Availability Zones.

ALB (Application Load Balancer): The public entry point. It accepts traffic on port 80 and forwards it to the Fargate task on port 3000. It also performs health checks against the /health endpoint.

ECS (Elastic Container Service):

Cluster: A serverless cluster for Fargate tasks.

Fargate Service: Manages the running task, ensuring the desired count is always running and handling rolling deployments.

ECR (Elastic Container Registry): A private Docker registry to store the application image.

SSM (Systems Manager Parameter Store): Securely stores environment variables (like RAILS_ENV) which are injected into the container at runtime.

CloudWatch: A log group is provisioned to collect logs from the running Fargate task.

S3 & DynamoDB: Used for the Terraform remote backend, providing state locking and persistence.

GitHub Actions (CI/CD):

Authenticates to AWS via OIDC (no static keys).

Builds the Docker image and pushes it to ECR.

Runs terraform apply to create/update infrastructure (including the new CloudWatch log group).

Triggers a new ECS deployment with the new image.

Waits for the service to become stable.

Runs a final curl health check against the public ALB to verify success.

🚀 Technology Stack

Application: Ruby (Sinatra + Puma)

Containerization: Docker (Multi-stage build)

Infrastructure as Code: Terraform

CI/CD: GitHub Actions

Cloud Provider: AWS

Compute: ECS Fargate

Networking: VPC, ALB, Route Tables

Storage: S3 (for Terraform state), ECR (for Docker images)

Security & Config: IAM (OIDC), SSM Parameter Store

Monitoring: CloudWatch Logs

📁 Project Structure

.
├── .github/workflows/deploy.yml   # CI/CD Pipeline
├── infra/                         # All Terraform files
│   ├── alb.tf
│   ├── cloudwatch.tf
│   ├── ecr.tf
│   ├── ecs.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── ssm.tf
│   ├── variables.tf
│   └── vpc.tf
├── app.rb                         # Sinatra API application
├── config.ru                      # Rackup file for Puma
├── Dockerfile                     # Multi-stage Docker build
├── .dockerignore
├── Gemfile
└── Gemfile.lock


🏁 Deployment Guide

Follow these steps to deploy the project from scratch.

Prerequisites

An AWS Account

AWS CLI configured locally

Terraform CLI installed

Docker Desktop installed

Ruby & Bundler installed (for Gemfile.lock generation)

Step 1: Local Application Test (Optional but Recommended)

Verify the application works locally before deploying.

# 1. Install local Ruby gems
bundle install

# 2. Build the Docker image
docker build -t rails-api .

# 3. Run the container
docker run -d -p 8080:3000 --name rails-api-test rails-api

# 4. Test the health endpoint
curl http://localhost:8080/health
# Expected output: {"status":"ok"}

# 5. Clean up
docker stop rails-api-test && docker rm rails-api-test


Step 2: AWS Prerequisites (Terraform Backend)

The CI/CD pipeline and local Terraform need a remote backend to store the state file. Create this once using the AWS CLI.

Note: S3 bucket names are globally unique. Choose a unique name for YOUR_STATE_BUCKET_NAME.

# Set your variables
export STATE_BUCKET_NAME="<YOUR-UNIQUE-STATE-BUCKET-NAME>"
export LOCK_TABLE_NAME="devops-lock-table"
export AWS_REGION="eu-central-1" # Must match variables.tf

# 1. Create the S3 bucket
aws s3api create-bucket \
    --bucket $STATE_BUCKET_NAME \
    --region $AWS_REGION \
    --create-bucket-configuration LocationConstraint=$AWS_REGION

# 2. Create the DynamoDB table for state locking
aws dynamodb create-table \
    --table-name $LOCK_TABLE_NAME \
    --region $AWS_REGION \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5


Step 3: Configure main.tf

Update your infra/main.tf file's backend block with the names you just created:

backend "s3" {
  bucket         = "<YOUR-UNIQUE-STATE-BUCKET-NAME>" # From Step 2
  key            = "rails-ecs/terraform.tfstate"
  region         = "eu-central-1"
  dynamodb_table = "devops-lock-table"               # From Step 2
  encrypt        = true
}


Step 4: GitHub OIDC & Secrets Setup

The pipeline uses OIDC for secure, keyless authentication.

Create AWS OIDC Provider:

In the IAM Console, go to Identity providers.

Click Add provider.

Select OpenID Connect.

Provider URL: https://token.actions.githubusercontent.com

Audience: sts.amazonaws.com

Create IAM Role (GitHubOIDCRole):

In the IAM Console, go to Roles > Create role.

Select Custom trust policy.

Use the Trust Policy JSON (see docs/iam-policy.json in this project) replacing your Account ID and GitHub Org/Repo.

On the permissions screen, create and attach the Inline Permissions Policy JSON (also in docs/iam-policy.json) replacing all 4 placeholders (<YOUR_ACCOUNT_ID>, <YOUR_REGION>, <YOUR_STATE_BUCKET_NAME>, <YOUR_LOCK_TABLE_NAME>).

Name the role GitHubOIDCRole.

Configure GitHub Secrets:

In your GitHub repo, go to Settings > Secrets and variables > Actions.

Create the following three secrets:

Secret Name

Value

AWS_ACCOUNT_ID

Your 12-digit AWS Account ID

TF_STATE_BUCKET

The name of your S3 state bucket from Step 2

TF_LOCK_TABLE

The name of your DynamoDB table from Step 2

Step 5: Run the First Deploy Manually

The CI/CD pipeline is designed to be idempotent. It's best to run the first deployment manually to provision the base infrastructure.

# Navigate to the infrastructure folder
cd infra

# Initialize the backend
terraform init

# Plan and Apply
terraform apply --auto-approve


(This will take 5-10 minutes to provision the VPC, ALB, and ECS cluster).

Step 6: Trigger the CI/CD Pipeline

With the infrastructure in place, commit and push all your project files. This will trigger the automated workflow.

git add .
git commit -m "Initial project setup and CI/CD"
git push origin main


The GitHub Action will now:

Log in via OIDC.

Build and push the Docker image to ECR.

Run terraform apply (which will create the CloudWatch log group and update the ECS task definition with the new image tag).

Deploy the new task to ECS.

Wait for the service to be stable.

Run the final health check.

✅ How to Verify

After the GitHub Actions workflow succeeds, you can verify the deployment:

Get the ALB URL from Terraform:

cd infra
terraform output alb_dns_name


Test the endpoint:

curl $(terraform output -raw alb_dns_name)/health
# Expected output: {"status":"ok"}


🧹 Cleanup

To destroy all AWS resources and avoid charges, run the following command from the infra directory:

terraform destroy --auto-approve
