#!/bin/bash

usage() {
    echo "Usage: dockerflow delete [-n vm_name]"
    echo " -n name of virtual machine"
    echo " -h Show this help message"
}

name=""

while getopts "n:h" opt; do
    case $opt in
        n) name="$OPTARG";;
        h) usage; exit 0;;
        *) usage; exit 1;;
    esac
done

if [ -z "$name" ]; then
    echo "Please provide a VM name you want to delete"
    usage
    exit 1
fi

sudo virsh destroy "$name"
sudo virsh undefine "$name" --remove-all-storage
