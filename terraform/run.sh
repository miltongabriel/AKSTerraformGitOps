#!/usr/bin/env bash

set -euo pipefail

STEP_DIR=${1:-}
ENVIRONMENT="${2:-$ENVIRONMENT}"
OLD_PATH="${PWD}"

export TF_PLUGIN_CACHE_DIR="$(git rev-parse --show-toplevel)/terraform/.terraform.d/plugin-cache"

if [[ ! -d "${TF_PLUGIN_CACHE_DIR}" ]]; then
  mkdir -p "${TF_PLUGIN_CACHE_DIR}"
fi

if [[ -z "${ENVIRONMENT}" ]]; then
  echo "Error: ENVIRONMENT is not set. Please provide the environment name."
  exit 1
fi

if [[ -z "${STEP_DIR}" ]]; then
  echo "Error: STEP_DIR is not set. Please provide the path to the Terraform step directory."
  exit 1
fi

if [[ ! -d "${STEP_DIR}" ]]; then
  echo "Error: Terraform step directory does not exist: ${STEP_DIR}"
  exit 1
fi

cd "${STEP_DIR}"
if [[ "${STEP_DIR}" == "00-backend"* ]]; then
  terraform init -reconfigure
else
  terraform init -compact-warnings -reconfigure --backend-config=../profiles/${ENVIRONMENT}.tfconfig
fi
terraform apply -compact-warnings -var-file=../profiles/${ENVIRONMENT}.tfvars
cd "${OLD_PATH}"
