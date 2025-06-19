#!/bin/bash

# Skrypt do tworzenia VM z obrazów qcow2 oraz raw

usage() {
  echo "Użycie: $0 [-n name_vm] [-i image] [-f format] [-m memory] [-v vcpus] [-s disk_size] [-h]"
  echo "  -n  Name of virtual machine (wymagane)"
  echo "  -i  Obraz dla VM (domyślnie fedora-core-41.qcow2) - obrazy w /var/lib/libvirt/images/"
  echo "  -f  Format obrazu: qcow2 lub raw (domyślnie qcow2)"
  echo "  -m  Pamięć RAM w MB (domyślnie 2048)"
  echo "  -v  Liczba vCPU (domyślnie 2)"
  echo "  -s  Rozmiar dodatkowego dysku w GB (domyślnie 20)"
  echo "  -h  Pomoc"
  exit 1
}

# Domyślne wartości
name=""
image="fedora-core-41.qcow2"
format="qcow2"
memory=2048
vcpus=2
size=20

# Parsowanie parametrów
while getopts "n:i:f:m:v:s:h" opt; do
  case $opt in
    n) name="$OPTARG" ;;
    i) image="$OPTARG" ;;
    f) format="$OPTARG" ;;
    m) memory="$OPTARG" ;;
    v) vcpus="$OPTARG" ;;
    s) size="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

# Sprawdzenie nazwy VM
if [[ -z "$name" ]]; then
  echo "Error: podaj nazwę VM za pomocą -n."
  usage
fi

# Ścieżki
img_src="/var/lib/libvirt/images/$image"
base_vol="/var/lib/libvirt/volumes/${name}-base.$format"
data_vol="/var/lib/libvirt/volumes/${name}-data.$format"

# Tworzenie katalogu wolumenów, jeśli nie istnieje
sudo mkdir -p /var/lib/libvirt/volumes /var/lib/libvirt/ignition

# Kopiowanie lub konwersja głównego obrazu (backing)
if [[ "$format" == "qcow2" ]]; then
  sudo qemu-img convert -f "$format" -O qcow2 "$img_src" "$base_vol"
else
  sudo cp "$img_src" "$base_vol"
fi

# Tworzenie dodatkowego dysku (pusty)
sudo qemu-img create -f "$format" "$data_vol" "${size}G"

# Instalacja VM z przekazaniem dodatkowego parametru qemu
sudo virt-install \
  --name "$name" \
  --memory "$memory" \
  --vcpus "$vcpus" \
  --import \
  --boot hd \
  --disk path="$base_vol",format="$format" \
  --disk path="$data_vol",format="$format" \
  --os-variant generic \
  --qemu-commandline="-fw_cfg name=opt/com.coreos/config,file=/var/lib/libvirt/ignition/worker.ign" \
  --network network=default \
  --noautoconsole

