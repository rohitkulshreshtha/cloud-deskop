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

.PHONY: cloud-ip
cloud-ip:
	@terraform output -raw public_ip