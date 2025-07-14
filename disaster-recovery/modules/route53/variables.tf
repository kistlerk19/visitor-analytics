variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the application (optional)"
  type        = string
  default     = ""
}

variable "enable_dr" {
  description = "Enable disaster recovery resources"
  type        = bool
  default     = false
}

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
}

variable "primary_alb_dns" {
  description = "Primary ALB DNS name"
  type        = string
}

variable "dr_alb_dns" {
  description = "DR ALB DNS name"
  type        = string
  default     = ""
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}