#!/bin/bash


TS=$(date +"%Y-%m-%d_%H-%M-%S")

REPO_NAME="$1"

LOG_DIR="/var/log/dockerflow/ansible_logs"

LOG_FILE="${LOG_DIR}/${REPO_NAME}_${TS}.log"

sudo mkdir -p "$LOG_DIR"
sudo chown hypervisoradmin:hypervisoradmin "$LOG_DIR"

sudo -u hypervisoradmin ansible-playbook -i localhost, \
  /usr/local/bin/dockerflow_config/playbooks/deployment_pipeline.yml \
  -e "repo_name=${REPO_NAME}" \
  --extra-vars "@/usr/local/bin/dockerflow_config/playbooks/token" \
  --connection=local \
  -v >> "$LOG_FILE" 2>&1

echo "Log zapisano do: ${LOG_FILE}"
