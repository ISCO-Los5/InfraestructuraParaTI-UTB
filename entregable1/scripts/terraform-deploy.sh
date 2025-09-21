set -e

terraform -chdir=./iac/terraform init
terraform -chdir=./iac/terraform validate
terraform -chdir=./iac/terraform plan
terraform -chdir=./iac/terraform apply  # If needed, add -auto-approve flag
