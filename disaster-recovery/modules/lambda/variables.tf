variable "project_name" {
  description = "Name of the project"
  type        = string
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

variable "dr_region" {
  description = "DR AWS region"
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

variable "notification_email" {
  description = "Email for notifications"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}