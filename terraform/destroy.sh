#!/bin/bash

OLD_PATH="${PWD}"
ENVIRONMENT="${2:-$ENVIRONMENT}"

if [[ -z "${ENVIRONMENT}" ]]; then
  echo "Error: ENVIRONMENT is not set. Please provide the environment name."
  exit 1
fi

find . -type d -iname '[0-9][0-9]-*' | grep -v "00-backend"
echo "Steps to be destroyed above. Please confirm by typing 'yes' to proceed:"
read confirmation

if [[ "${confirmation}" != "yes" ]]; then
  echo "Destruction aborted."
  exit 1
fi

for STEP_DIR in $(find . -type d -iname '[0-9][0-9]-*' | grep -v "00-backend"); do
  echo "-----------------------------------------------"
  echo -e "\n\n Destroying Terraform step: $i \n\n"
  echo "-----------------------------------------------"
  sleep 5
  cd "${STEP_DIR}"
  terraform destroy -var-file=../profiles/${ENVIRONMENT}.tfvars
  terraform init -compact-warnings -reconfigure --backend-config=../profiles/${ENVIRONMENT}.tfconfig
  cd "${OLD_PATH}"
done