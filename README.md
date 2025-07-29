# Automated Jenkins EC2 Deployment with Terraform

## Overview  
**Automated Jenkins EC2 Deployment with Terraform** provisions an AWS EC2 instance and bootstraps Jenkins via a user-data script, enabling consistent, version-controlled CI/CD infrastructure. This approach accelerates onboarding, reduces manual configuration errors, and ensures reproducible environments across teams.

## Prerequisites  
Before you begin, ensure you have:  
- An AWS account with permissions to create EC2 instances, VPCs, security groups, IAM roles, and key pairs  
- Terraform v1.5 or later installed and on your PATH  
- A Git client (e.g., Git for Windows, macOS Command Line Tools, or Git on Linux)  
- An existing AWS EC2 SSH key pair (public key uploaded to EC2 Key Pairs)  
- (Optional) AWS CLI configured (`aws configure`)  

## Repository Structure  
```text
.
├── main.tf                  # Terraform provider and resource definitions  
├── variables.tf             # Input variable definitions  
├── outputs.tf               # Output values (e.g., public IP)  
├── terraform.tfvars         # Variable values (not checked in)  
├── jenkins_bootstrap.sh     # User-data script to install and configure Jenkins  
└── README.md                # Project documentation  
```

## Setup Instructions

1. **Clone the repository**  
   ```bash
   git clone https://github.com/BhaktaBhusanDas/JenkinsSetupUsingTerraform.git
   cd JenkinsSetupUsingTerraform
   ```

2. **Define variable values**  
   - Copy or create `terraform.tfvars` in the project root  
   - Add your values:
     ```hcl
     jenkins_admin_username = "JenkinsAdmin"
     jenkins_admin_password = "JenkinsAdmin"
     environment         = "production"
     key_name = "Path\of\Your\KeyPair.pem"
     ```

3. **Initialize Terraform**  
   ```bash
   terraform init
   ```

4. **Validate the configuration**  
   ```bash
   terraform validate
   ```

5. **Preview the deployment plan**  
   ```bash
   terraform plan
   ```

6. **Apply the configuration**  
   ```bash
   terraform apply
   ```
   - Type `yes` when prompted.  
   - Terraform will provision the EC2 instance and execute `jenkins_bootstrap.sh` to install Jenkins.

## Example Usage

```bash
# In project directory
terraform init
terraform apply -auto-approve
```

After completion, Terraform outputs will display the public DNS or IP of your Jenkins server. Navigate to:  
```
http://<EC2_PUBLIC_IP_OR_DNS>:8080
```
Use the admin username and password that you mentioned in the`terraform.tfvars`.