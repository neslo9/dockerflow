#!/bin/bash
# Path: /usr/local/bin/dockerflow

usage() {
  echo "Użycie: $0 [-a] [-n image] [-s status] [-l] [-h]"
  echo ""
  echo "  -a              Pokaż wszystkie wpisy (domyślnie)"
  echo "  -n <image>      Filtruj po nazwie obrazu"
  echo "  -s <status>     Filtruj po statusie"
  echo "  -l              Pokaż tylko najnowsze wpisy dla każdego obrazu"
  echo "  -h              Pomoc"
  exit 1
}

list_images() {
    local log_file="/var/log/dockerflow/history.csv"
    local show_all=true
    local latest_only=false
    local image_filter=""
    local status_filter=""

    mkdir -p "$(dirname "$log_file")"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -a) show_all=true; shift ;;
            -n) image_filter="$2"; show_all=false; shift 2 ;;
            -s) status_filter="$2"; show_all=false; shift 2 ;;
            -l) latest_only=true; shift ;;
            -h|--help) usage ;;
            *) echo "Nieznana opcja: $1" >&2; usage ;;
        esac
    done

    if [ ! -f "$log_file" ]; then
        echo "Brak zapisanych uruchomień pipelinu"
        return
    fi

    declare -A latest_entries
    declare -a all_entries

    # Czytamy plik, 4 kolumny: timestamp,image,status,image_id
    while IFS=, read -r timestamp image status image_id; do
        # Trim whitespace
        timestamp="${timestamp#"${timestamp%%[![:space:]]*}"}"
        timestamp="${timestamp%"${timestamp##*[![:space:]]}"}"
        image="${image#"${image%%[![:space:]]*}"}"
        image="${image%"${image##*[![:space:]]}"}"
        status="${status#"${status%%[![:space:]]*}"}"
        status="${status%"${status##*[![:space:]]}"}"
        image_id="${image_id#"${image_id%%[![:space:]]*}"}"
        image_id="${image_id%"${image_id##*[![:space:]]}"}"
        [[ -z $timestamp || -z $image || -z $status || -z $image_id ]] && continue

        # Filtry
        [[ -n $image_filter && $image != *"$image_filter"* ]] && continue
        [[ -n $status_filter && $status != "$status_filter" ]] && continue

        all_entries+=("$timestamp,$image,$status,$image_id")

        # Najnowszy wpis dla obrazu?
        if [[ -z ${latest_entries[$image]} || $timestamp > ${latest_entries[$image]%%,*} ]]; then
            latest_entries[$image]="$timestamp,$status,$image_id"
        fi
    done < <(tac -- "$log_file" 2>/dev/null)

    if [[ ${#all_entries[@]} -eq 0 ]]; then
        echo "Brak pasujących wpisów"
        return
    fi

    printf "%-40s %-20s %-19s %s\n" "IMAGE" "STATUS" "TIMESTAMP" "IMAGE ID"

    if $latest_only; then
        for img in $(printf "%s\n" "${!latest_entries[@]}" | sort); do
            IFS=, read -r ts st imgid <<< "${latest_entries[$img]}"
            printf "%-40s %-20s %-19s %s\n" "$img" "$st" "$ts" "$imgid"
        done
    else
        for entry in "${all_entries[@]}"; do
            IFS=, read -r ts img st imgid <<< "$entry"
            printf "%-40s %-20s %-19s %s\n" "$img" "$st" "$ts" "$imgid"
        done
    fi
}

# Domyślne wywołanie: zawsze list_images
list_images "$@"
