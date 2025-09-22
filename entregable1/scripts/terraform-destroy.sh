set -e

terraform -chdir=./iac/terraform destroy  # If needed, add -auto-approve flag
