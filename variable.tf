variable "tags" {
  type        = map(any)
  description = "Tags to apply to resources, where applicable"
  default     = {
      "Name" : "aws_security",
      "Envirnoment" : "prod"

  }
}