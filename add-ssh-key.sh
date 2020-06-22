#!/usr/bin/env bash
set -e
eval $(ssh-agent -s)

echo "Do a SSH add with the key under env 'SSH_PRIVATE_KEY'"
mkdir -p ~/.ssh/
cp /ssh/* ~/.ssh/

chmod 600 ~/.ssh/id_rsa

echo "Set StrictHostKeyChecking no"
echo -e "Host *\n\tStrictHostKeyChecking no\n\n" > ~/.ssh/config