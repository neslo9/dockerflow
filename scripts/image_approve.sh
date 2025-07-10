#!/bin/bash

usage(){
    echo "Usage: dockerflow image-approve"
    echo "  -i image ID (optional)"
    echo "  -t target image tag (optional, e.g. myrepo:latest)"
    echo "  -s status (optional, default: approved)"
    echo "  -h show this message"
    echo
    echo "You must specify either -i or -t"
}

image_id=""
target_image=""
status="approved"

while getopts "i:t:s:h" opt; do
    case $opt in
        i) image_id="$OPTARG";;
        t) target_image="$OPTARG";;
        s) status="$OPTARG";;
        h) usage; exit 0;;
        *) usage; exit 1;;
    esac
done

if [[ -z "$image_id" && -z "$target_image" ]]; then
    echo "Error: either image ID (-i) or target image (-t) must be provided."
    usage
    exit 1
fi

if [[ -n "$image_id" && -z "$target_image" ]]; then
    TAGS=$(docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | grep "$image_id" | awk '{print $1}')
    if [[ -z "$TAGS" ]]; then
        echo "No tags found for image ID: $image_id"
        exit 2
    fi
    target_image=$(echo "$TAGS" | head -n1)
fi

# Wyciągnij nazwę serwisu jako repozytorium (np. "project/test_app1" -> "test_app1")
service_name=$(echo "$target_image" | cut -d':' -f1 | awk -F '/' '{print $NF}')

project="project"
harbor_url="192.168.122.101:30002"
harbor_password=""
log_file="/var/log/dockerflow/history.csv"

echo "Approving & tagging image:"
echo "  Target Image  : $target_image"
echo "  Service Name  : $service_name"
echo "  Project       : $project"
echo "  Status        : $status"
echo "  Log File      : $log_file"
echo

ansible-playbook /usr/local/bin/dockerflow_config/playbooks/tag_and_push.yml \
  -e "target_image=$target_image" \
  -e "service_name=$service_name" \
  -e "harbor_url=$harbor_url" \
  -e "project=$project" \
  -e "harbor_password=$harbor_password" \
  -e "log_file=$log_file" \
  -e "service_status=$status" \
  -vv
