provider "aws" {
  region = var.aws_region // Choose your preferred region
}

provider "tls" {}

locals {
  ssh_key_name = "${var.desktop_name}-key"

  local_tags = merge(var.tags, {
    "CloudDesktop" = var.desktop_name
  })
}


resource "aws_resourcegroups_group" "project_group" {
  name        = "${var.desktop_name}-resource-group"
  description = "Resource group for all resources with Project tag matching ${var.desktop_name}"

  resource_query {
    query = jsonencode({
      "ResourceTypeFilters": ["AWS::AllSupported"],
      "TagFilters": [
        {
          "Key": "CloudDesktop",
          "Values": [var.desktop_name]
        }
      ]
    })
  }
}

resource "aws_key_pair" "cloud_desktop_key" {
  key_name   = local.ssh_key_name
  public_key = file("~/.ssh/cloud-desktop-key.pub")
  tags = merge(local.local_tags, {})
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = merge(local.local_tags, {})
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = merge(local.local_tags, {})
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = merge(local.local_tags, {})
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(local.local_tags, {})
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "instance" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  // Open SSH to the world (configure as needed)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.local_tags, {})
}

resource "aws_instance" "cloud_desktop" {
  ami                    = var.ami // Amazon Linux 2023 AMI
  instance_type          = var.instance_type
  key_name               = aws_key_pair.cloud_desktop_key.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.instance.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.instance_volume_size // Size in GB, adjust as needed
  }

  tags = merge(local.local_tags, {
    Name = "CloudDesktop-${var.desktop_name}"
  })
}


resource "null_resource" "setup_cloud_desktop" {
  depends_on = [aws_instance.cloud_desktop]

  provisioner "remote-exec" {
    inline = [
      # Update the system
      "sudo dnf update -y", # Amazon Linux (adjust for other AMIs if needed)

      # Install Git
      "sudo dnf install -y git",  # Amazon Linux (adjust for other AMIs if needed)

      # Install Development Tools
      "sudo dnf groupinstall -y \"Development Tools\"",

      # Install Zsh
      "sudo dnf install -y zsh",
      # Change the default shell to Zsh for ec2-user
      "sudo usermod -s $(which zsh) ec2-user",
      # Install Oh My Zsh for ec2-user
      "sudo -u ec2-user sh -c \"$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh) --unattended\"",
      # Set Oh My Zsh theme to agnoster
      "sudo -u ec2-user sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"agnoster\"/' /home/ec2-user/.zshrc",

      # Install AWS CLI v2
      "curl \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip\" -o \"awscliv2.zip\"",
      "unzip awscliv2.zip",
      "sudo ./aws/install",

      # Install Docker
      "sudo dnf install docker -y",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo usermod -aG docker ec2-user",

      # Install Minikube dependencies
      "sudo dnf install -y conntrack",

      # Download and install Minikube
      "curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64",
      "chmod +x minikube",
      "sudo mv minikube /usr/local/bin/",

      # Download and install kubectl
      "curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl",
      "chmod +x kubectl",
      "sudo mv kubectl /usr/local/bin/",

      # Verify installations
      "docker --version",
      "minikube version",
      "kubectl version --client",

      # Install Rust
      "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y",

      # Install Terraform
      "sudo dnf install -y dnf-plugins-core",
      "sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo",
      "sudo dnf -y install terraform",

      # Install jq
      "sudo dnf install -y jq",    # Amazon Linux (adjust for other AMIs if needed)
    ]

    connection {
      type        = "ssh"
      host        = aws_instance.cloud_desktop.public_ip
      user        = "ec2-user" # Adjust based on your AMI
      private_key = file("~/.ssh/${local.ssh_key_name}")
    }
  }
}

