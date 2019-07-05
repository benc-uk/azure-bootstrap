#!/bin/bash

DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"

# Load variables
source "$DIR/vars.sh"

echo -e "\n\e[34m╔══════════════════════════════════╗"
echo -e "║                                  ║"
echo -e "║\e[33m  Azure Project Bootstrapper\e[34m 🚀   ║"
echo -e "║                                  ║"
echo -e "╚══════════════════════════════════╝"
echo -e "\e[31m »»» \e[35mBen Coleman, 2019    \e[39m[v0.0.1]"

echo -e "\e[31m »»» ✍ \e[32mCreating Azure DevOps project \e[1m'$ADO_PROJECT'\e[0m..."
az devops project create --name $ADO_PROJECT --description "$ADO_PROJECT_DESC" --org $ADO_ORG --process $ADO_PROJECT_PROCESS -o table

echo -e "\e[31m »»» 📥 \e[32mCreating repo \e[1m'$ADO_PROJECT'\e[0m\e[32m and importing from \e[1m'$REPO_SOURCE'\e[0m..."
az repos create --name $REPO_NAME --org $ADO_ORG --project $ADO_PROJECT -o table
az repos import create --repository $REPO_NAME --organization $ADO_ORG  --git-source-url $REPO_SOURCE --project $ADO_PROJECT -o table
echo ""