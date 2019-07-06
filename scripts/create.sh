#!/bin/bash

DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"

# Load variables
source "$DIR/vars.sh"

echo -e "\n\e[34m╔═══════════════════════════════╗"
echo -e "║                               ║"
echo -e "║\e[33m  Azure Project Bootstrapper\e[34m   ║"
echo -e "║                               ║"
echo -e "╚═══════════════════════════════╝"
echo -e "    🚀👢🚀  \e[36mLet's go!! 👢🚀👢\n"
echo -e "\e[31m »»» \e[35mBen Coleman, 2019    \e[39m[v0.0.1]"

# Check pre-reqs for az CLI and az devops extension 
echo -e "\e[31m »»» 🍳  \e[32mRunning pre-req checks\e[0m..."
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
echo -e "\e[31m »»» 🍳  \e[32mAzure subscription and account:\e[35m"
az account show --query "{Subscription:name, SubscriptionID:id, UserName:user.name}" -o yaml
echo ""
read -p "Are these details correct and you wish to continue? " -n 1 -r
echo    # (optional) move to a new line
if ! [[ $REPLY =~ ^[Yy]$ ]]
then
  echo -e "\e[31m !!! OK, let's get out of here! 🍺"
  exit
fi

echo -e "\e[31m »»» ✍  \e[32mCreating Azure DevOps project \e[1m'$ADO_PROJECT'\e[0m..."
az devops project create --name $ADO_PROJECT --description "$ADO_PROJECT_DESC" --org $ADO_ORG --process $ADO_PROJECT_PROCESS -o table

#echo -e "\e[31m »»» 📥  \e[32mCreating repo \e[1m'$ADO_PROJECT'\e[0m\e[32m and importing from \e[1m'$REPO_SOURCE'\e[0m..."
#az repos create --name $REPO_NAME --org $ADO_ORG --project $ADO_PROJECT -o table
#az repos import create --repository $REPO_NAME --organization $ADO_ORG  --git-source-url $REPO_SOURCE --project $ADO_PROJECT -o table
#echo ""

az devops service-endpoint create --name $GITHUB_CONN_NAME --service-endpoint-type github --github-url https://github.com/benc-uk --authorization-scheme PersonalAccessToken --project $ADO_PROJECT --organization $ADO_ORG -o table

az pipelines create --name 'Deploy Azure Core' --yml-path pipelines/deploy-core.yml --repository $REPO_SOURCE --branch master --service-connection $GITHUB_CONN_NAME --project $ADO_PROJECT --organization $ADO_ORG -o table
