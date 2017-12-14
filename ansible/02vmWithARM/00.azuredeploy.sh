#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# -e: immediately exit if any command has a non-zero exit status
# -o: prevents errors in a pipeline from being masked
# IFS new value is less likely to cause confusing bugs when looping arrays or arguments (e.g. $@)

usage() { echo "Usage: $0 -g <resourceGroupName> -n <deploymentName> -u <adminUserId> -r <vaultResourceGroup> -v <vaultName> -s <secretName> -c <customDataFile>" 1>&2; exit 1; }


declare subscriptionId="7b13dc94-2b54-4cdf-a247-bbdebdb97f4f"
declare resourceGroupName=""
declare resourceGroupLocation=koreacentral
declare deploymentName=""
declare adminUserId=""
declare vaultResourceGroup=""
declare vaultName=""
declare secretName=""
declare customDataFile=""
declare IP_RES_ID=""
declare FQDN=""

# Initialize parameters specified from command line
while getopts ":g:n:u:r:v:s:c:" arg; do
    case "${arg}" in
        g)
            resourceGroupName=${OPTARG}
            ;;
        n)
            deploymentName=${OPTARG}
            ;;
        u)
            adminUserId=${OPTARG}
            ;;
        r)
            vaultResourceGroup=${OPTARG}
            ;;
        v)
            vaultName=${OPTARG}
            ;;
        s)
            secretName=${OPTARG}
            ;;
        c)
            customDataFile=${OPTARG}
            ;;
        esac
done
shift $((OPTIND-1))

#Prompt for parameters is some required parameters are missing
if [[ -z "$adminUserId" ]]; then
    echo "adminUserId :"
    read adminUserId
    [[ "${adminUserId:?}" ]]
fi

if [[ -z "$resourceGroupName" ]]; then
    echo "ResourceGroupName:"
    read resourceGroupName
    [[ "${resourceGroupName:?}" ]]
fi

if [[ -z "$deploymentName" ]]; then
    echo "deploymentName:"
    read deploymentName
    [[ "${deploymentName:?}" ]]
fi

if [[ -z "$vaultResourceGroup" ]]; then
    echo "Key Vault Resource Group:"
    read vaultResourceGroup
    [[ "${vaultResourceGroup:?}" ]]
fi

if [[ -z "$vaultName" ]]; then
    echo "Vault Name:"
    read vaultName
    [[ "${vaultName:?}" ]]
fi

if [[ -z "$secretName" ]]; then
    echo "secretName which public key resides :"
    read secretName
    [[ "${secretName:?}" ]]
fi

if [[ -z "$customDataFile" ]]; then
    echo "customDataFile name:"
    read customDataFile
fi

#templateFile Path - template file to be used
templateFilePath="00.azuredeploy.json"

if [ ! -f "$templateFilePath" ]; then
    echo "$templateFilePath not found"
    exit 1
fi

#parameter file path
parametersFilePath="00.azuredeploy.parameters.json"

if [ ! -f "$parametersFilePath" ]; then
    echo "$parametersFilePath not found"
    exit 1
fi

if [ -z "$resourceGroupName" ] || [ -z "$adminUserId" ] || [ -z "$vaultResourceGroup" ] || [ -z "$vaultName" ] || [ -z "$secretName" ] || [ -z "$customDataFile" ]; then
    echo "Some required parameters are missing"
    usage
    exit 1
fi

#login to azure using your credentials
az account show 1> /dev/null

if [ $? != 0 ];
then
    az login
fi

#set the default subscription id
az account set --subscription $subscriptionId

#Check for existing RG
if [ $(az group exists --name $resourceGroupName) == 'false' ]; then
    echo "Resource group with name" $resourceGroupName "could not be found. Creating new resource group.."
    (
        set -x
        az group create --name $resourceGroupName --location $resourceGroupLocation 1> /dev/null
    )
    else
    echo "Using existing resource group..."
fi

#Start deployment
echo "Starting deployment..."

customData=$(cat $customDataFile|base64)
set -x
IP_RES_ID=`az group deployment create --name $deploymentName --resource-group $resourceGroupName --template-file $templateFilePath \
--parameters @$parametersFilePath \
--parameters adminUserId=$adminUserId \
--parameters vaultResourceGroup=$vaultResourceGroup \
--parameters vaultName=$vaultName \
--parameters secretName=$secretName \
--parameters customData=$customData| jq -r '.properties.outputs.pubicIPId.value'`

if [ $?  == 0 ];
then
    echo "Template has been successfully deployed"
    FQDN=`az network public-ip show --ids $IP_RES_ID| jq -r '.dnsSettings.fqdn'`
    echo "fqdn=$FQDN"
#### /etc/ansible/hosts에 넣기 위해서 hosts파일을 write권한은 주어야 함.
    if grep -Fq "$FQDN" /etc/ansible/hosts;
    then
        echo "already this vm is in ansible default inventory. Skipping.."
    else
        echo "$FQDN ansible_ssh_private_key_file=/Users/minsoojo/.ssh/minscho_ebay.com.pem">> /etc/ansible/hosts
    fi
    
    ansible $FQDN -m ping
fi