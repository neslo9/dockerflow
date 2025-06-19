#!/bin/bash

usage(){
    echo "Usage: dockerflow-connect [-n vm_name] [-u user]"
    echo "  -n name of virtual machine"
    echo "  -u user [default worker]"
    echo "  -h Show this help message"
}

name=""
user="worker"

while getopts "n:u:h" opt; do
    case $opt in
        n) name="$OPTARG";;
        u) user="$OPTARG";;
        h) usage; exit 0;;
        *) usage; exit 1;;
    esac
done

# Sprawdzanie, czy zmienna name nie jest pusta
if [ -z "$name" ]; then
    echo "Please provide the name of the virtual machine."
    usage
    exit 1
fi

ip=$(sudo virsh domifaddr "$name" | grep ipv4 | awk '{print $4}' | cut -d'/' -f1)

if [ -z "$ip" ]; then
    echo "Could not retrieve IP address for VM '$name'."
    exit 1
fi

sudo ssh -i /home/hypervisoradmin/.ssh/id_rsa "$user"@"$ip"
