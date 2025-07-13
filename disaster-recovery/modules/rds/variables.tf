variable "project_name" {
  description = "Project name"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "RDS security group ID"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "enable_dr" {
  description = "Enable disaster recovery"
  type        = bool
  default     = false
}

variable "dr_subnet_group_name" {
  description = "DR region subnet group name"
  type        = string
  default     = ""
}

variable "dr_rds_security_group_id" {
  description = "DR region RDS security group ID"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}