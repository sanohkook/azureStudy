#!/bin/bash
set -euo pipefail 
echo $1
if grep -Fq "$1" /etc/ansible/hosts;
then
  echo "already this vm is in ansible default inventory. Skipping.."
else
  echo "$1 ansible_ssh_private_key_file=/home/bit4man/.ssh/id_rsa">> /etc/ansible/hosts
fi
