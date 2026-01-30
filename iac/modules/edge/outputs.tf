output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.cdn.domain_name
}

output "cloudfront_distribution_arn" {
  value = aws_cloudfront_distribution.cdn.arn
}

output "waf_arn" {
  value = aws_wafv2_web_acl.edge.arn
}
