#!/bin/bash

usage(){
    echo "Usage: dockerflow deploy-logs"
    echo "  -n name of image (required)"
    echo "  -d date of deployment (optional, format YYYY-MM-DD)"
    echo "  -l follow log output (live updates)"
    echo "  -h show this message"
}

name=""
date=""
follow="false"

while getopts "n:d:lh" opt; do
    case $opt in
        n) name="$OPTARG";;
        d) date="$OPTARG";;
        l) follow="true";;
        h) usage; exit 0;;
        *) usage; exit 1;;
    esac
done

if [[ -z "$name" ]]; then
    echo "Error: name is required."
    usage
    exit 1
fi

log_dir="/var/log/dockerflow/ansible_logs"

if [[ -n "$date" ]]; then
    matches=($(ls "$log_dir/${name}_${date}"*.log 2>/dev/null))

    if [[ ${#matches[@]} -eq 0 ]]; then
        echo "No logs found for $name on $date"
        exit 1
    elif [[ ${#matches[@]} -eq 1 ]]; then
        logfile="${matches[0]}"
    else
        echo "Multiple logs found for $name on $date:"
        select logfile in "${matches[@]}"; do
            if [[ -n "$logfile" ]]; then
                break
            else
                echo "Invalid selection."
            fi
        done
    fi
else
    # Brak daty - pokaż najnowszy log
    logfile=$(ls -t "$log_dir/${name}_"*.log 2>/dev/null | head -n 1)
    if [[ -z "$logfile" ]]; then
        echo "No logs found for $name"
        exit 1
    fi
    echo "Showing latest log: $logfile"
fi

if [[ "$follow" == "true" ]]; then
    tail -f "$logfile"
else
    cat "$logfile"
fi


echo
read -p "Do you approve this image deployment? (y/N): " confirm

if [[ "$confirm" =~ ^[Yy]$ ]]; then
    image_id=$(docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | grep "$name" | awk '{print $2}' | head -n 1)
    if [[ -z "$image_id" ]]; then
        echo "Could not find image ID for $name"
        exit 1
    fi

    echo "Running image-approve for image ID: $image_id..."
    dockerflow image-approve -i "$image_id"
else
    echo "Image approval skipped."
fi
