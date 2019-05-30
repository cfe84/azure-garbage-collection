#!/bin/bash

PWD=`pwd`
random() { size=$1; echo -n `date +%s%N | sha256sum | base64 | head -c $size`;}

while [[ $# -gt 0 ]]
do
    key="$1"
    shift

    case $key in
        -n|--name)
            NAME="$1"
            shift
        ;;
        -l|--location)
            LOCATION="$1"
            shift
        ;;
        *)
            echo "Unknown parameter: $key"
            usage
        ;;
    esac
done


RANDOMBASE="`random 5`"
SUBSCRIPTIONID="`az account show --query id -o tsv`"
SUBSCRIPTION_RESOURCE_ID="/subscriptions/$SUBSCRIPTIONID"
NAME="`basename "$PWD"`"

if [ ! -f env.sh ]; then
    echo "#!/bin/bash

NAME='$NAME'
LOCATION=\"westus2\"
RANDOMBASE=\"$RANDOMBASE\"
RANDOMBASE16CHAR=\"`random 16`\"
STORAGEBASENAME=\"`echo -n $NAME | head -c 15`$RANDOMBASE\"
SUBSCRIPTIONID=\"$SUBSCRIPTIONID\"
SUBSCRIPTION_RESOURCE_ID=\"$SUBSCRIPTION_RESOURCE_ID\"
TENANTID=`az  account show --query tenantId -o tsv`
" > env.sh
fi


source env.sh

usage() {
    echo "Usage: `basename "$0"` [--name $NAME] [--location $LOCATION]"
    exit 1
}





echo "This will provision the following resources: "
echo "ResourceGroup (default)"
echo "StorageAccount (default)"
echo "FunctionApp (default)"

DEFAULT_RESOURCE_GROUP="$NAME"
DEFAULT_RESOURCE_GROUP_RESOURCE_ID="$SUBSCRIPTION_RESOURCE_ID/resourceGroups/$DEFAULT_RESOURCE_GROUP"
DEFAULT_STORAGE_ACCOUNT="`echo "$STORAGEBASENAME" | sed -e 's/-//g' | sed -E 's/^(.*)$/\L\1/g' | head -c 20`def"
DEFAULT_STORAGE_ACCOUNT_RESOURCE_ID="$DEFAULT_RESOURCE_GROUP_RESOURCE_ID/providers/Microsoft.Storage/storageAccounts/$DEFAULT_STORAGE_ACCOUNT"
DEFAULT_FUNCTIONAPP="$NAME-$RANDOMBASE"
DEFAULT_FUNCTIONAPP_HOSTNAME="https://$DEFAULT_FUNCTIONAPP.azurewebsites.net"

echo "Creating resource group $DEFAULT_RESOURCE_GROUP"
az group create --name $DEFAULT_RESOURCE_GROUP --location $LOCATION --query "properties.provisioningState" -o tsv
echo "Creating storage account $DEFAULT_STORAGE_ACCOUNT"
az storage account create --name $DEFAULT_STORAGE_ACCOUNT --kind StorageV2 --sku Standard_LRS --location $LOCATION -g $DEFAULT_RESOURCE_GROUP --https-only true --query "provisioningState" -o tsv
DEFAULT_STORAGE_ACCOUNT_CONNECTION_STRING=`az storage account show-connection-string -g $DEFAULT_RESOURCE_GROUP -n $DEFAULT_STORAGE_ACCOUNT --query connectionString -o tsv`



echo "Creating functionapp $DEFAULT_FUNCTIONAPP"
az functionapp create -g $DEFAULT_RESOURCE_GROUP --consumption-plan-location $LOCATION --name $DEFAULT_FUNCTIONAPP --storage-account $DEFAULT_STORAGE_ACCOUNT --query "state" -o tsv
az functionapp config appsettings set --name $DEFAULT_FUNCTIONAPP -g $DEFAULT_RESOURCE_GROUP --settings SUBSCRIPTION=$SUBSCRIPTIONID DEFAULT_EXPIRY_DAYS=14 DEFAULT_TAG=experiment > /dev/null
echo "Configuring identity for functionapp $DEFAULT_FUNCTIONAPP with contributor access to scope $SUBSCRIPTION_RESOURCE_ID. Principal id:"
DEFAULT_FUNCTIONAPP_PRINCIPALID=`az functionapp identity assign --name $DEFAULT_FUNCTIONAPP --resource-group $DEFAULT_RESOURCE_GROUP --role contributor --scope "$SUBSCRIPTION_RESOURCE_ID" --query principalId -o tsv`
echo "Deploying function app $DEFAULT_FUNCTIONAPP"
func azure functionapp publish $DEFAULT_FUNCTIONAPP

echo "Generating cleanup script"
echo "#!/bin/bash
echo 'Removing resource group $DEFAULT_RESOURCE_GROUP'
az group delete --name $DEFAULT_RESOURCE_GROUP --yes
echo 'Removing function app identity $DEFAULT_FUNCTIONAPP_PRINCIPALID'
    az ad app delete --id $DEFAULT_FUNCTIONAPP_PRINCIPALID
rm env.sh
" > cleanup.sh
chmod +x cleanup.sh
        
echo "    Resource group name: $DEFAULT_RESOURCE_GROUP"
echo "  Storage account (def): $DEFAULT_STORAGE_ACCOUNT"
echo "      Storage key (def): $DEFAULT_STORAGE_ACCOUNT_CONNECTION_STRING"
echo "          Function Name: $DEFAULT_FUNCTIONAPP"
echo "           Function URL: $DEFAULT_FUNCTIONAPP_HOSTNAME"

