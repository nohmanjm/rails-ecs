resource "aws_cloudwatch_log_group" "ecs_task_logs" {
  name              = "/ecs/${var.project_name}-task-definition"
  retention_in_days = 7 # Optional: Set log retention

  tags = {
    Project = var.project_name
  }
}