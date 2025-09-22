set -e

ansible-playbook -i iac/ansible/inventory ./iac/ansible/nginx.yaml
