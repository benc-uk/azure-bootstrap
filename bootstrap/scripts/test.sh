#!/bin/bash
DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
# Load variables
source "$DIR/../vars.sh"

az devops service-endpoint create --service-endpoint-configuration docker-conn.json --project $ADO_PROJECT --organization $ADO_ORG