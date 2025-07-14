variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "enable_dr" {
  description = "Enable disaster recovery resources"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}