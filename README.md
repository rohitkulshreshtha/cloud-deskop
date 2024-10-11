# Cloud Desktop

This project provisions an AWS EC2 instance as a cloud desktop using Terraform. 

* The instance is created in a public subnet with a public IP address.
* The instance is accessible via SSH. 
* The following packages are installed on the instance:
  * Zsh
  * Oh My Zsh
  * Git
  * Development Tools (gcc, make, etc.)  
  * Docker
  * jq
  * minikube
  * kubectl
  * AWS CLI
  * Terraform

## Prerequisites

- **AWS CLI**: Installed and configured with proper credentials. [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).
- **Terraform**: Installed on your local machine. [Install Terraform](https://www.terraform.io/downloads.html).
- **Make**: Installed on your local machine (typically available on macOS and Linux). [Install Make](https://www.gnu.org/software/make/).

### macOS
On macOS, you can install the prerequisites using [Homebrew](https://brew.sh/):

```bash
brew install awscli terraform make
```

### AWS Account

You need an AWS account to provision the cloud desktop. If you don't have an AWS account, 
you can create one [here](https://aws.amazon.com/). Setup your AWS CLI with the credentials
of the account. See [Configuring the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html).

## Configuration

The `variables.tf` file contains the configuration for the cloud desktop.

## Usage

### Clone the Repository

```bash
git clone git@github.com:rohitkulshreshtha/cloud-deskop.git 
cd cloud-desktop
```

### Initialize Terraform

```bash
make terraform-init
```

### Provision the Cloud Desktop

```bash
make terraform-apply
```

### SSH into the Cloud Desktop

```bash
make ssh
```

## View all the resources created in AWS
```bash
make view-resources
```

## Destroy the cloud desktop and all local files/resources

```bash
make clean
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
