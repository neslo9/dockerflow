#!/bin/bash

usage(){
    echo "Usage: dockerflow list [lists all vms]"
    echo "  -h Show this help message"
}	
 
sudo virsh list --all
