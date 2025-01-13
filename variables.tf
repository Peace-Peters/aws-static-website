
# Updated variables.tf file content
variable "my_bucket_region" {
  description = "My Default bucket region"
  type        = string
  default     = "us-east-1"
}

variable "my_bucket_name" {
  description = "My Bucket name"
  type        = string
  default     = "peace-hello-world"
}