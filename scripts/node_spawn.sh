#!/bin/bash
set -euo pipefail


usage() {
  cat <<EOF
Usage: dockerflow masternode-spawn
Options:
  -n name (required)
  -i basic image /var/lib/libvirt/images/ (default Fedora-Cloud-Base.qcow2)
  -f qcow2 lub raw (default qcow2)
  -m RAM w MB (default 2048)
  -v vcpus Number of vCPU (default 2)
  -s disk size in GB (default 20)
  -u path to cloud-init user-data 
  -d path to cloud-init meta-data
  -w path to cloud-init network-config
  -h show this message
EOF
  exit 1
}

# Domyślne wartości
image="Fedora-Cloud-Base-40-1.14.x86_64.qcow2"
format="qcow2"
memory=2048
vcpus=2
size=20
user_data="/usr/local/bin/dockerflow_config/cloud-init/user-data"
meta_data="/usr/local/bin/dockerflow_config/cloud-init/meta-data"
network_config="/usr/local/bin/dockerflow_config/cloud-init/network-config"

# Parse opts
while getopts "n:i:f:m:v:s:u:d:w:h" opt; do
  case $opt in
    n) name="$OPTARG" ;;
    i) image="$OPTARG" ;;
    f) format="$OPTARG" ;;
    m) memory="$OPTARG" ;;
    v) vcpus="$OPTARG" ;;
    s) size="$OPTARG" ;;
    u) user_data="$OPTARG" ;;
    d) meta_data="$OPTARG" ;;
    w) network_config="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

# Check required
if [[ -z "${name:-}" ]] || [[ -z "${user_data:-}" ]] || [[ -z "${meta_data:-}" ]] || [[ -z "${network_config:-}" ]]; then
  echo "Parameter missing"
  usage
fi

# Paths
IMG_SRC="/var/lib/libvirt/images/$image"
BASE_VOL="/var/lib/libvirt/volumes/${name}-base.$format"
DATA_VOL="/var/lib/libvirt/volumes/${name}-data.$format"
CI_ISO="/var/lib/libvirt/images/${name}-cloudinit.iso"

# Create dirs
sudo mkdir -p /var/lib/libvirt/volumes /var/lib/libvirt/images

# Prepare base volume
if [[ "$format" == "qcow2" ]]; then
  sudo qemu-img convert -f "$format" -O qcow2 "$IMG_SRC" "$BASE_VOL"
else
  sudo cp "$IMG_SRC" "$BASE_VOL"
fi

# Create data volume
sudo qemu-img create -f "$format" "$DATA_VOL" "${size}G"

# Generate cloud-init ISO
sudo cloud-localds -v  \
  --network-config="$network_config" \
  "$CI_ISO" "$user_data" "$meta_data"

# Create VM
sudo virt-install \
  --name "$name" \
  --memory "$memory" \
  --vcpus "$vcpus" \
  --import \
  --boot hd \
  --disk path="$BASE_VOL",format="$format" \
  --disk path="$DATA_VOL",format="$format" \
  --disk path="$CI_ISO",device=cdrom \
  --os-variant fedora40 \
  --network network=default \
  --noautoconsole

echo " Node '$name' has been created"
