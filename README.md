AWS ECS Fargate Deployment for Ruby API
This project deploys a containerized Ruby (Sinatra) API to AWS ECS Fargate, provisioned with Terraform, and automated with GitHub Actions using OIDC.
The application serves a single /health endpoint returning {"status":"ok"}.

🚀 Technology Stack
Application: Ruby (Sinatra + Puma)
Containerization: Docker (Multi-stage build)
Infrastructure: Terraform
CI/CD: GitHub Actions
Cloud: AWS (ECS Fargate, ALB, ECR, VPC, S3, DynamoDB, SSM, CloudWatch)

🏁 Deployment Guide
Step 1: AWS Prerequisites (Terraform Backend)
Create an S3 bucket (e.g., my-tf-state-bucket-unique) and a DynamoDB table (e.g., my-tf-lock-table with LockID as the partition key) in your AWS account. Update infra/main.tf with their names.

Step 2: GitHub OIDC & Secrets Setup
AWS IAM: Create an OIDC provider for token.actions.githubusercontent.com.
AWS IAM: Create a role (GitHubOIDCRole) with a trust policy for your GitHub repo and attach the necessary IAM permissions for ECR, ECS, S3, DynamoDB, and Terraform read-only actions.

GitHub Secrets: In your repo settings, add the following secrets:
AWS_ACCOUNT_ID: Your 12-digit AWS Account ID.
TF_STATE_BUCKET: Your S3 bucket name from Step 1.
TF_LOCK_TABLE: Your DynamoDB table name from Step 1.

Step 3: Run the Initial Deploy Manually
This provisions the base infrastructure.

# Navigate to the infrastructure folder
cd infra

# Initialize the backend
terraform init

# Plan and Apply
terraform apply --auto-approve


Step 4: Trigger the CI/CD Pipeline
Commit and push all project files to the main branch.

git add .
git commit -m "Initial project setup"
git push origin main


The GitHub Action will now automatically build, push, and deploy the application.

✅ How to Verify

Get the ALB URL:

cd infra
terraform output -raw alb_dns_name


Test the endpoint:

curl $(terraform output -raw alb_dns_name)/health
# Expected output: {"status":"ok"}


🧹 Cleanup

cd infra
terraform destroy --auto-approve
