# Output the public IP address of the EC2 instance
output "public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.cloud_desktop.public_ip
}

# Output the instance ID
output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.cloud_desktop.id
}

output "desktop_name" {
  value       = var.desktop_name
  description = "Name of the Cloud Desktop."
}

output "aws_region" {
    value       = var.aws_region
    description = "AWS region where the Cloud Desktop is deployed."
}