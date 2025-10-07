output "security_group_id" {
  description = "Security group for interface endpoints"
  value       = aws_security_group.endpoints.id
}

output "endpoint_ids" {
  description = "Map of VPC endpoint IDs"
  value = {
    s3         = aws_vpc_endpoint.s3.id
    ecr_dkr    = aws_vpc_endpoint.dkr.id
    ecr_api    = aws_vpc_endpoint.api.id
    logs       = aws_vpc_endpoint.logs.id
    secrets    = aws_vpc_endpoint.secrets.id
    cloudwatch = aws_vpc_endpoint.cloudwatch.id
  }
}
