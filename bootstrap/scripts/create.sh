#!/bin/bash

DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"

# Load variables
source "$DIR/../vars.sh"

echo -e "\n\e[34m╔═══════════════════════════════╗"
echo -e "║                               ║"
echo -e "║\e[33m  Azure Project Bootstrapper\e[34m   ║"
echo -e "║                               ║"
echo -e "╚═══════════════════════════════╝"
echo -e "    🚀👢🚀  \e[36mLet's go!! 👢🚀👢\n"
echo -e "\e[34m »»» \e[35mBen Coleman, 2019    \e[39m[v0.0.1]"

# Check pre-reqs for az CLI and az devops extension 
echo -e "\e[34m »»» 🍳  \e[32mRunning pre-req checks\e[0m..."
az > /dev/null 2>&1
if [ $? -ne 0  ]; then
  echo -e "\e[31m !!! Azure CLI is not installed! Please go to http://aka.ms/cli to set it up"
  exit
fi
az devops -h > /dev/null 2>&1
if [ $? -ne 0  ]; then
  echo -e "\e[31m !!! Azure DevOps CLI is not installed! Please go to https://github.com/Azure/azure-devops-cli-extension#quick-start to set it up"
  exit
fi

# Show azure details and prompt user to continue 
echo -e "\e[34m »»» 🍳  \e[32mAzure subscription and account:\e[35m"
az account show --query "{Subscription:name, SubscriptionID:id, UserName:user.name}" -o yaml
echo ""
read -p "Are these details correct and you wish to continue? " -n 1 -r
echo    # (optional) move to a new line
if ! [[ $REPLY =~ ^[Yy]$ ]]
then
  echo -e "\e[31m !!! OK, let's get out of here! 🍺"
  exit
fi

# Munge values into vars.sh 
AZURE_SUB_ID=$(az account show --query "id" -o tsv)
AZURE_SUB_NAME=$(az account show --query "name" -o tsv)
AZURE_TENANT_ID=$(az account show --query "tenantId" -o tsv)
sed "s/AZURE_TENANT_ID=\".*\"/AZURE_TENANT_ID=\"$AZURE_TENANT_ID\"/g" -i "$DIR/../vars.sh"
sed "s/AZURE_SUB_ID=\".*\"/AZURE_SUB_ID=\"$AZURE_SUB_ID\"/g" -i "$DIR/../vars.sh"
sed "s/AZURE_SUB_NAME=\".*\"/AZURE_SUB_NAME=\"$AZURE_SUB_NAME\"/g" -i "$DIR/../vars.sh"

echo -e "\e[34m »»» ✍  \e[32mCreating Azure DevOps project \e[1m'$ADO_PROJECT'\e[0m..."
az devops project create --name $ADO_PROJECT --description "$ADO_PROJECT_DESC" --org $ADO_ORG --process $ADO_PROJECT_PROCESS -o table

#####az repos create --name $REPO_NAME --org $ADO_ORG --project $ADO_PROJECT -o table
#####az repos import create --repository $REPO_NAME --organization $ADO_ORG  --git-source-url $REPO_SOURCE --project $ADO_PROJECT -o table

echo -e "\e[34m »»» 🤖  \e[32mCreating Service Principal \e[1m'$SP_NAME'\e[0m..."
AZURE_SP_SECRET=$(az ad sp create-for-rbac --name "$SP_NAME" --query password -o tsv)

echo -e "\e[34m »»» ⏱  \e[32mWaiting 60 seconds for identity to fully propogate\e[0m..."
sleep 60
AZURE_SP_ID=$(az ad sp list --spn "http://$SP_NAME" --query "[0].appId" -o tsv)
echo -e "\e[34m »»» 🍳  \e[32mNew service principal ID: \e[1m'$SP_ID\e[0m"

sed "s/AZURE_SP_ID=\".*\"/AZURE_SP_ID=\"$AZURE_SP_ID\"/g" -i "$DIR/../vars.sh"
sed "s/AZURE_SP_SECRET=\".*\"/AZURE_SP_SECRET=\"$AZURE_SP_SECRET\"/g" -i "$DIR/../vars.sh"
export AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY="$AZURE_SP_SECRET"

echo -e "\e[34m »»» 🔌  \e[32mCreating DevOps connection to GitHub using PAT\e[0m..."
az devops service-endpoint create --name $GITHUB_CONN_NAME --service-endpoint-type github --github-url https://github.com --authorization-scheme PersonalAccessToken --project $ADO_PROJECT --organization $ADO_ORG -o table
GITHUB_CONN_ID=$(az devops service-endpoint list --project $ADO_PROJECT --organization $ADO_ORG --query "[?name == '$GITHUB_CONN_NAME'].id" -o tsv)
echo -e "\e[34m »»» 🍳  \e[32mConnection ID is \e[1m'$GITHUB_CONN_ID'\e[0m..."

echo -e "\e[34m »»» 🔌  \e[32mCreating DevOps connection to Azure using Service Principal\e[0m..."
az devops service-endpoint create --name $AZURE_CONN_NAME --service-endpoint-type azurerm --azure-rm-subscription-id $AZURE_SUB_ID --azure-rm-tenant-id $AZURE_TENANT_ID --azure-rm-subscription-name "$AZURE_SUB_NAME" --azure-rm-service-principal-id $AZURE_SP_ID --authorization-scheme ServicePrincipal --project $ADO_PROJECT --organization $ADO_ORG -o table
AZURE_CONN_ID=$(az devops service-endpoint list --project $ADO_PROJECT --organization $ADO_ORG --query "[?name == '$AZURE_CONN_NAME'].id" -o tsv)
echo -e "\e[34m »»» 🍳  \e[32mConnection ID is \e[1m'$GITHUB_CONN_ID'\e[0m..."

echo -e "\e[34m »»» ✍  \e[32mCreating pipeline \e[1m'Deploy Azure Core'\e[0m..."
az pipelines create --name 'Deploy Azure Core' --yml-path bootstrap/pipelines/deploy-core.yml --repository $GITHUB_REPO --branch dev --service-connection $GITHUB_CONN_ID --project $ADO_PROJECT --organization $ADO_ORG -o table
