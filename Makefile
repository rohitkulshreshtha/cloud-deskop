# Variables
KEY_NAME = cloud-desktop-key
KEY_PATH = ~/.ssh/$(KEY_NAME)
TF_VARS_FILE = terraform.tfvars

# Default target
.PHONY: all
all: generate-key terraform-apply

# Target to generate SSH key pair
.PHONY: generate-key
generate-key:
	@echo "Generating SSH key pair..."
	@if [ ! -f $(KEY_PATH) ]; then \
		ssh-keygen -t rsa -b 4096 -f $(KEY_PATH) -N ""; \
		echo "SSH key generated at $(KEY_PATH)"; \
	else \
		echo "SSH key already exists at $(KEY_PATH). Skipping generation."; \
	fi

# Target to initialize Terraform
.PHONY: terraform-init
terraform-init:
	@echo "Initializing Terraform..."
	terraform init

# Target to apply Terraform configuration
.PHONY: terraform-apply
terraform-apply: terraform-init
	@echo "Applying Terraform configuration..."
	terraform apply

# Target to destroy Terraform resources
.PHONY: terraform-destroy
terraform-destroy:
	@echo "Destroying Terraform resources..."
	terraform destroy

# Target to clean up SSH key pair
.PHONY: clean-key
clean-key:
	@echo "Cleaning up SSH key pair..."
	@if [ -f $(KEY_PATH) ]; then \
		rm -f $(KEY_PATH) $(KEY_PATH).pub; \
		echo "SSH key pair removed from $(KEY_PATH)"; \
	else \
		echo "No SSH key found at $(KEY_PATH)."; \
	fi

# Target to clean up Terraform files
.PHONY: clean-terraform
clean-terraform:
	@echo "Cleaning up Terraform files..."
	rm -rf .terraform/ terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl

# Full cleanup target
.PHONY: clean
clean: terraform-destroy clean-key clean-terraform
	@echo "All generated files have been cleaned up."

# Target to SSH into the EC2 instance with Agent Forwarding enabled
.PHONY: ssh
ssh:
	@echo "Fetching EC2 instance public IP..."
	@IP=$$(terraform output -raw public_ip); \
	if [ -n "$$IP" ]; then \
		echo "Connecting to $$IP..."; \
		ssh -A -i $(KEY_PATH) ec2-user@$$IP; \
	else \
		echo "Public IP not found. Make sure the instance is running and has a public IP."; \
	fi

# Open browser to view the AWS Resource Group
.PHONY: view-resources
view-resources:
	@AWS_REGION=$$(terraform output -raw aws_region); \
	DESKTOP_NAME=$$(terraform output -raw desktop_name); \
	open "https://console.aws.amazon.com/resource-groups/group/$$DESKTOP_NAME-resource-group?region=$$AWS_REGION"

.PHONY: cloud-upload
cloud-upload:
	@echo "Fetching EC2 instance public IP for upload..."
	@file=$(word 2, $(MAKECMDGOALS)); \
	dest=$(word 3, $(MAKECMDGOALS)); \
	IP=$$(terraform output -raw public_ip); \
	if [ -n "$$IP" ]; then \
		echo "Uploading file to $$IP..."; \
		scp -i $(KEY_PATH) "$$file" ec2-user@$$IP:"$$dest"; \
	else \
		echo "Public IP not found. Ensure the instance is running and has a public IP."; \
	fi

# Target to download a file from the EC2 instance
.PHONY: cloud-download
cloud-download:
	@echo "Fetching EC2 instance public IP for download..."
	@remote_file=$(word 2, $(MAKECMDGOALS)); \
	local_dest=$(word 3, $(MAKECMDGOALS)); \
	IP=$$(terraform output -raw public_ip); \
	if [ -n "$$IP" ]; then \
		echo "Downloading file from $$IP..."; \
		scp -i $(KEY_PATH) ec2-user@$$IP:"$$remote_file" "$$local_dest"; \
	else \
		echo "Public IP not found. Ensure the instance is running and has a public IP."; \
	fi

# Capture positional arguments for cloud-upload and cloud-download
cloud-upload-%:
	@:

cloud-download-%:
	@: