set -e

mkdir -p ./keys
ssh-keygen -t rsa -b 2048 -f ./keys/id_rsa
