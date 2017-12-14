#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# -e: immediately exit if any command has a non-zero exit status
# -o: prevents errors in a pipeline from being masked
# IFS new value is less likely to cause confusing bugs when looping arrays or arguments (e.g. $@)

usage() { echo "Usage: $0 -t <targetGroupName> -n <networkGroupName> -i <nicName> -v <vmName> -u <adminUserId> -k <sshKeyData>" 1>&2; exit 1; }

declare targetGroupName=""
declare targetGroupLocation=koreacentral
declare networkGroupName=""
declare nicName=""
declare vmName=""
declare adminUserId=""
declare sshKeyData=""

# Initialize parameters specified from command line
while getopts ":t:n:i:v:u:k:" arg; do
    case "${arg}" in
        t)
            targetGroupName=${OPTARG}
            ;;
        n)
            networkGroupName=${OPTARG}
            ;;
        i)
            nicName=${OPTARG}
            ;;
        v)
            vmName=${OPTARG}
            ;;
        u)
            adminUserId=${OPTARG}
            ;;
        k)
            sshKeyData=${OPTARG}
            ;;
        esac
done
shift $((OPTIND-1))

#Prompt for parameters is some required parameters are missing

if [[ -z "$targetGroupName" ]]; then
    echo "Target Group Name for creation and deploy to :"
    read targetGroupName
    [[ "${targetGroupName:?}" ]]
fi

if [[ -z "$networkGroupName" ]]; then
    echo "Network Group Name where NIC is included in :"
    read networkGroupName
    [[ "${networkGroupName:?}" ]]
fi

if [[ -z "$nicName" ]]; then
    echo "Network Card Name for this VM :"
    read nicName
    [[ "${nicName:?}" ]]
fi

if [[ -z "$vmName" ]]; then
    echo "vm Name :"
    read nicName
    [[ "${nicName:?}" ]]
fi

if [[ -z "$adminUserId" ]]; then
    echo "adminUserId for this VM :"
    read adminUserId
    [[ "${adminUserId:?}" ]]
fi

if [[ -z "$sshKeyData" ]]; then
    echo "sshKeyData for this user :"
    read sshKeyData
fi

if [ -z "$vmName" ] || [ -z "$adminUserId" ] || [ -z "$sshKeyData" ]; then
    echo "Either one of vmName, adminUserId, sshKeyData is empty"
    usage
fi

echo "Terraform Apply will be running with environment variables ARM_SUBSCRIPTION_ID,ARM_CLIENT_SECRET,ARM_TENANT_ID,ARM_CLIENT_ID"
echo "If all of above environments are missing, terraform apply will be failed."

#Start deployment
echo "Starting deployment..."
(
    set -x
    terraform apply -auto-approve -var targetRgName=$targetGroupName -var vmName=$vmName -var adminId=$adminUserId -var adminKey=$sshKeyData
)

if [ $?  == 0 ];
then
    echo "Template has been successfully deployed"
fi