#!/bin/bash
set -euox pipefail
IFS=$'\n\t'

usage() { echo "Usage: $0 -g <resourceGroupName>" 1>&2; exit 1; }

declare subscriptionId="7b13dc94-2b54-4cdf-a247-bbdebdb97f4f"
declare resourceGroupName=""
declare resourceGroupLocation=koreacentral

# Initialize parameters specified from command line
while getopts ":g:" arg; do
    case "${arg}" in
        g)
            resourceGroupName=${OPTARG}
            ;;
    esac
done
shift $((OPTIND-1))

if [[ -z "$resourceGroupName" ]]; then
    echo "ResourceGroupName:"
    read resourceGroupName
    [[ "${resourceGroupName:?}" ]]
fi

if [ $(az group exists --name $resourceGroupName) == 'false' ]; then
    echo "Resource group with name" $resourceGroupName "could not be found. Creating new resource group.."
    (
        set -x
        az group create --name $resourceGroupName --location $resourceGroupLocation 1> /dev/null
    )
    else
    echo "Using existing resource group..."
fi

az group deployment create \
--resource-group $resourceGroupName \
--template-file 02.azuredeploy.json \
--parameters @02.azuredeploy.parameters.json

# ansible inventory에 넣으려면..
pemFilePath=" ansible_ssh_private_key_file=/Users/minsoojo/.ssh/minscho_ebay.com.pem"
az vmss list-instance-public-ips \
--resource-group minschoTestRG01 \
--name mySet01 |jq -r '.[].dnsSettings.fqdn' | sed "s|$|$pemFilePath|" >> /etc/ansible/hosts