variable "tags" {
  description = "AWS tags to apply to all resources."
  type        = map(string)
  default     = {
    # Add as needed.
  }
}

variable "aws_region" {
  description = "The AWS region to deploy the cloud desktop in"
  type        = string
  default     = "us-east-2" # Modify as needed
}

# EC2 instance type
variable "instance_type" {
  description = "The type of instance to run for the cloud desktop"
  type        = string
  default     = "c7i.8xlarge" # Modify as needed
}

# Size of the EBS volume to attach (in GB)
variable "instance_volume_size" {
  description = "The size of the root volume for the cloud desktop"
  type        = number
  default     = 100 # GB
}

# Name of the desktop, used to name resources like keys and instance tags
variable "desktop_name" {
  description = "The name of the desktop, used for naming resources like keys and instance tags"
  type        = string
  default     = "cloud-desktop"
}

# AMI to use for the cloud desktop
variable "ami" {
  description = "The image ID to use for the cloud desktop"
  type        = string
  default     = "ami-09da212cf18033880" # Amazon Linux 2023 AMI
}