variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "dr_region" {
  description = "Disaster recovery AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "notification_email" {
  description = "Email for notifications"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "enable_dr" {
  description = "Enable disaster recovery resources"
  type        = bool
  default     = false
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "domain_name" {
  description = "Domain name for the application (optional)"
  type        = string
  default     = ""
}