#!/bin/bash


TS=$(date +"%Y-%m-%d_%H-%M-%S")

REPO_NAME="$1"

LOG_DIR="/var/log/dockerflow/ansible_logs"

LOG_FILE="${LOG_DIR}/${REPO_NAME}_${TS}.log"

sudo mkdir -p "$LOG_DIR"
sudo chown admin:admin "$LOG_DIR"

sudo -u admin ansible-playbook -i localhost, \
  /usr/local/bin/dockerflow_config/playbooks/main.yml \
  -e "repo_name=${REPO_NAME}" \
  --extra-vars "@/usr/local/bin/dockerflow_config/playbooks/token" \
  --connection=local \
  -vv >> "$LOG_FILE" 2>&1

echo "Log zapisano do: ${LOG_FILE}"
