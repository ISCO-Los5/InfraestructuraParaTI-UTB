set -e

if [ ! -d "./iac/terraform/.terraform" ]; then
    terraform -chdir=./iac/terraform init
fi

terraform -chdir=./iac/terraform validate
terraform -chdir=./iac/terraform plan
terraform -chdir=./iac/terraform apply  # If needed, add -auto-approve flag
