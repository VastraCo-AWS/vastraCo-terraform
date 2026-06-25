output "bucket_id" {
  description = "Product images S3 bucket name"
  value       = aws_s3_bucket.product_images.id
}

output "bucket_arn" {
  description = "Product images S3 bucket ARN"
  value       = aws_s3_bucket.product_images.arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the product images bucket"
  value       = aws_s3_bucket.product_images.bucket_regional_domain_name
}

output "oac_id" {
  description = "CloudFront Origin Access Control ID for the product images bucket"
  value       = aws_cloudfront_origin_access_control.product_images.id
}
