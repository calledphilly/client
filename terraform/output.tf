output "cloudfront_url" {
  value       = "https://${aws_cloudfront_distribution.core.domain_name}"
  description = "L'URL CloudFront complète avec https://"
}