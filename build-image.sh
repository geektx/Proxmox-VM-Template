#! /bin/sh

# This script will download and modify the desired image to prep for template build.
# Script is inspired by 2 separate authors work.
# Austins Nerdy Things: https://austinsnerdythings.com/2021/08/30/how-to-create-a-proxmox-ubuntu-cloud-init-image/
# What the Server: https://whattheserver.com/proxmox-cloud-init-os-template-creation/
# requires libguestfs-tools to be installed.
# This script is designed to be run inside the ProxMox VE host environment.
# Modify the install_dir variable to reflect where you have placed the script and associated files.

. ./build-vars

# Clean up any previous build
rm ${install_dir}${image_name}
rm ${install_dir}build-info

# Grab latest cloud-init image for your selected image
wget ${cloud_img_url}

# insert commands to populate the currently empty build-info file
touch ${install_dir}build-info
echo "Base Image: "$(image_name) > ${install_dir}build-info
echo "Packages added at build time: "${package_list} >> ${install_dir}build-info
echo "Build date: "$(date) >> ${install_dir}build-info
echo "Build creator: "$(creator) >> ${install_dir}build-info

virt-customize --update -a ${image_name}
virt-customize --install ${package_list} -a ${image_name}
virt-customize --mkdir $(build-info-file-location) --copy-in ${install_dir}build-info:$(build-info-file-location) -a ${image_name}
qm destroy ${build_vm_id}
qm create ${build_vm_id} --memory ${vm_mem} --cores ${vm_cores} --net0 virtio,bridge=vmbr0 --name $(template-name)
qm importdisk ${build_vm_id} ${image_name} ${storage_location}
qm set ${build_vm_id} --scsihw ${scsihw} --scsi0 ${storage_location}:vm-${build_vm_id}-disk-0
qm set ${build_vm_id} --ide0 ${storage_location}:cloudinit
qm set ${build_vm_id} --nameserver ${nameserver} --ostype l26 --searchdomain ${searchdomain} --sshkeys ${keyfile} --ciuser $(cloud-init-user)
qm set ${build_vm_id} --boot c --bootdisk scsi0
#qm set ${build_vm_id} --serial0 socket --vga serial0
qm set ${build_vm_id} --agent enabled=1
qm template ${build_vm_id}
