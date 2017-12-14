#!/bin/bash
set -euo pipefail

cd ../02vmWithARM
/bin/bash 00.azuredeploy.sh -g sanohVMRG01 -n vmWithAnsible -u sanoh -r sanohVaultRG01 -v sanohVault -s sanohPub -c dummy-init.yaml
cd ../04CommonTasks
/usr/local/bin/ansible-playbook common_tasks.yml

