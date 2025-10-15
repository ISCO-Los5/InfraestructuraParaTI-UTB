set -e

if [ ! -d "./terraform/.terraform" ]; then
    terraform -chdir=./terraform init
fi

terraform -chdir=./terraform validate
terraform -chdir=./terraform plan
terraform -chdir=./terraform apply -auto-approve
terraform -chdir=./terraform output -raw private_key > los-cinco-key.pem
chmod 600 los-cinco-key.pem
