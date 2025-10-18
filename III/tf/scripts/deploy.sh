set -e

if [ ! -d ".terraform" ]; then
    terraform init
fi

terraform validate
terraform plan
terraform apply -auto-approve