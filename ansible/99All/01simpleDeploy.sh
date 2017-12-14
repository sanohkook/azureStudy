#!/bin/bash
set -euo pipefail

cd ../02vmWithARM
/bin/bash 00.azuredeploy.sh -g minschoTestRG01 -n vmWithAnsible -u minsoojo -r minschoVaultRG01 -v minschoVault -s minschoPub -c dummy-init.yaml
cd ../04CommonTasks
/usr/local/bin/ansible-playbook common_tasks.yml

