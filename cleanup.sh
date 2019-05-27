#!/bin/bash

echo 'Removing app registration https://prod-func-azure-garbage-collection-ODRlN.azurewebsites.net/'
az ad app delete --id https://prod-func-azure-garbage-collection-ODRlN.azurewebsites.net/
echo 'Removing resource group prod-func-azure-garbage-collection'
az group delete --name prod-func-azure-garbage-collection --yes



