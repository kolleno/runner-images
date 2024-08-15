packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

source "proxmox-iso" "pkr-ubuntu-jammy-1" {
  proxmox_url               = "${var.proxmox_api_url}"
  username                  = "${var.proxmox_api_token_id}"
  token                     = "${var.proxmox_api_token_secret}"
  insecure_skip_tls_verify  = true

  node                      = "prx-prod-1"
  vm_id                     = "90001"
  vm_name                   = "pkr-ubuntu-jammy-1"
  template_description      = "Ubuntu 22.04.4 LTS"

  iso_file                  = "local:iso/ubuntu-22.04.4-live-server-amd64.iso"
  iso_storage_pool          = "local"
  unmount_iso               = true
  qemu_agent                = true

  scsi_controller           = "virtio-scsi-pci"

  cores                     = "2"
  sockets                   = "1"
  memory                    = "4096"

  cloud_init                = true
  cloud_init_storage_pool   = "local-lvm"

  vga {
    type                    = "virtio"
  }

  disks {
    disk_size               = "20G"
    format                  = "raw"
    storage_pool            = "local-lvm"
    type                    = "virtio"
  }

  network_adapters {
    model                   = "virtio"
    bridge                  = "vmbr0"
    firewall                = "false"
  }

  boot_command = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    "<bs><bs><bs><bs><wait>",
    "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
    "<f10><wait>"
  ]

  boot                      = "c"
  boot_wait                 = "6s"
  communicator              = "ssh"

  http_directory            = "http"

  ssh_username              = "admin"
  ssh_password              = "supersecretpassword"

  # Raise the timeout, when installation takes longer
  ssh_timeout               = "30m"
  ssh_pty                   = true
  ssh_handshake_attempts    = 15
}

build {

  name    = "pkr-ubuntu-jammy-1"
  sources = [
    "proxmox-iso.pkr-ubuntu-jammy-1"
  ]

  # Waiting for Cloud-Init to finish
  provisioner "shell" {
    inline = ["cloud-init status --wait"]
  }

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
  provisioner "shell" {
    execute_command = "echo -e '<user>' | sudo -S -E bash '{{ .Path }}'"
    inline = [
      "echo 'Starting Stage: Provisioning the VM Template for Cloud-Init Integration in Proxmox'",
      "sudo rm /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo apt -y autoremove --purge",
      "sudo apt -y clean",
      "sudo apt -y autoclean",
      "sudo cloud-init clean",
      "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
      "sudo rm -f /etc/netplan/00-installer-config.yaml",
      "sudo sync",
      "echo 'Done Stage: Provisioning the VM Template for Cloud-Init Integration in Proxmox'"
    ]
  }

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
  provisioner "file" {
    source      = "files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }
  provisioner "shell" {
    inline = ["sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"]
  }
}
