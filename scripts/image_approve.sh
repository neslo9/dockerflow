#!/bin/bash

usage(){
    echo "Usage: dockerflow image-approve"
    echo "  -i image ID (required)"
    echo "  -s status (optional, default: approved)"
    echo "  -h show this message"
}

image_id=""
status="approved"

while getopts "i:s:h" opt; do
    case $opt in
        i) image_id="$OPTARG";;
        s) status="$OPTARG";;
        h) usage; exit 0;;
        *) usage; exit 1;;
    esac
done

if [[ -z "$image_id" ]]; then
    echo "Error: image ID is required."
    usage
    exit 1
fi

# Szukanie lokalnych tagów dla danego image ID
TAGS=$(docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | grep "$image_id" | awk '{print $1}')

if [[ -z "$TAGS" ]]; then
    echo "No tags found for image ID: $image_id"
    exit 2
fi

# Wybierz pierwszy tag spośród dostępnych
FIRST_TAG=$(echo "$TAGS" | head -n 1)
IMAGE_NAME=$(echo "$FIRST_TAG" | cut -d':' -f1 | awk -F '/' '{print $NF}')
LOCAL_TAG=$(echo "$FIRST_TAG" | cut -d':' -f2)

# Zmienne środowiskowe
HARBOR_URL="192.168.122.100"
PROJECT="project"

echo "Approving image:"
echo "  Image ID   : $image_id"
echo "  Name       : $IMAGE_NAME"
echo "  Tag        : $LOCAL_TAG"
echo "  Status     : $status"
echo

# Uruchomienie playbooka
ansible-playbook /usr/local/bin/dockerflow_config/playbooks/approve_push.yml \
  -e "image_name=$IMAGE_NAME" \
  -e "local_tag=$LOCAL_TAG" \
  -e "harbor_url=$HARBOR_URL" \
  -e "project=$PROJECT" \
  -e "status=$status"
