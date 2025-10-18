#!/bin/bash

set -a
source .env
set +a

ansible-playbook -i ansible/inventory.ini ansible/mysql-config.yml