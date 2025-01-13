
# Updated output.tf file content
output "cloudfront_url" {
  description = "CloudFront Distribution URL"
  value       = aws_cloudfront_distribution.cloudfront_distribution.domain_name
}
