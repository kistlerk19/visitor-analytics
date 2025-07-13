variable "project_name" {
  description = "Project name"
  type        = string
}

variable "enable_dr" {
  description = "Enable disaster recovery"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}