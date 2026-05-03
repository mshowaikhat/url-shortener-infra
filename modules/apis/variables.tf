variable "project_id" {
  type        = string
  description = "Project to enable APIs in"
}

variable "apis" {
  type        = list(string)
  description = "List of API service names to enable"
}