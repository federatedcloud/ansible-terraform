provider "google" {
  credentials = var.credentials 
  project = var.project_id
  region = var.region 
}
resource "random_id" "instance_id" {
  byte_length = 8
}
resource "google_compute_network" "openmpi_cluster" {
  name = "openmpi-cluster"
  project = var.project_id
}
resource "google_compute_subnetwork" "openmpi_cluster" {
  name = "openmpi-default-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  project = var.project_id
  region = var.region
  network = google_compute_network.openmpi_cluster.self_link
  
}
resource "google_compute_instance" "openmpi_base_vm" {
 name         = "openmpi-base-vm-${random_id.instance_id.hex}"
 machine_type = var.machine_type
 zone         = var.zone

 depends_on = [google_compute_network.openmpi_cluster,google_compute_subnetwork.openmpi_cluster]
 boot_disk {
   initialize_params {
     //GB size
     size = var.disk_size
     type = var.disk_type
     image = var.image
   }
 }
 metadata_startup_script = "echo"
 network_interface {
   network = "openmpi-cluster"
   access_config {
     // Include this section to give the VM a custom external ip address
   }
 }  
  metadata = {
   ssh-keys = "${var.USER}:${file("${var.PUBLIC_KEY}")}"
 }
###################################################################
# Ansible Script for Configuration on startup 
###################################################################
  provisioner "remote-exec" {
    # ensures that a connection is set up
        inline = ["echo"] 
    connection {
     type = "ssh"
     user = var.USER
     private_key = file(var.PRIVATE_KEY)
     host = google_compute_instance.openmpi_base_vm.network_interface.0.access_config.0.nat_ip
    }
  } 
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${var.USER}@${google_compute_instance.openmpi_base_vm.network_interface.0.access_config.0.nat_ip},' --private-key '${var.PRIVATE_KEY}' ../ansible/CentosPlaybook.yaml --extra-vars 'bitbucket_key='${var.BITBUCKET_KEY}' user='${var.USER}''"
  }
}

###################################################################
# Setting up Security Groups
###################################################################
resource "google_compute_firewall" "allow_ssh" {
  name = "allow-ssh"
  network = "openmpi-cluster"

  allow {
    protocol = "tcp"
    ports = ["22"]
  }
  source_ranges = ["128.84.0.0/16"]
  priority = "1000"
  depends_on = [google_compute_network.openmpi_cluster,google_compute_subnetwork.openmpi_cluster]
}
resource "google_compute_firewall" "allow_internal_tcp" {
  name = "allow-internal-tcp"
  network = "openmpi-cluster"
  
  allow {
    protocol = "tcp"
  }
  #TODO: edit this source range
  source_ranges = ["10.142.0.0/16"]
  priority = "1000"
  depends_on = [google_compute_network.openmpi_cluster,google_compute_subnetwork.openmpi_cluster]
}
resource "google_compute_firewall" "allow_all_ICMP" {
  name = "allow-all-icmp"
  network = "openmpi-cluster"
  
  allow {
    protocol = "icmp"
  }
  priority = "1000"
  depends_on = [google_compute_network.openmpi_cluster,google_compute_subnetwork.openmpi_cluster]
}

###################################################################
# Saving instance to snapshot
###################################################################
resource "google_compute_snapshot" "openmpi_base_vm" {
  name = "openmpi-base-vm-snapshot"
  source_disk = google_compute_instance.openmpi_base_vm.name
  zone = google_compute_instance.openmpi_base_vm.zone
  labels = {
    my_label = "open-base-vm"
  }
}
###################################################################
# Make disk from snapshot
###################################################################
resource "google_compute_disk" "openmpi_base_vm" {
  name = "openmpi-base-vm-disk"
  type = var.disk_type
  zone = google_compute_instance.openmpi_base_vm.zone
  snapshot = google_compute_snapshot.openmpi_base_vm.name
}
###################################################################
# Make image from disk
###################################################################
resource "google_compute_image" "openmpi_base_vm" {
  name = "openmpi-base-vm-image"
  source_disk = google_compute_disk.openmpi_base_vm.self_link
}
###################################################################
# Make new instances
###################################################################
resource "google_compute_instance" "mpi" {
 count = var.cluster_count 
 name         = "mpi-instances${count.index}"
 machine_type = var.machine_type
 zone         = var.zone

 boot_disk {
   initialize_params {
     size = var.disk_size
     type = var.disk_type
     image = google_compute_image.openmpi_base_vm.self_link 
   }
 }
 network_interface {
   network = "openmpi-cluster"

   access_config {
     // Include this section to give the VM a custom external ip address
   }
 }  
  metadata = {
   ssh-keys = "${var.USER}:${file(var.PUBLIC_KEY)}"
 }/*
 provisioner "remote-exec" {
   # ensures that a connection is set up
       inline = ["echo"] 
   connection {
    type = "ssh"
    user = var.USER
    private_key = file(var.PRIVATE_KEY)
    host = google_compute_instance.mpi.*.network_interface.0.network_ip
   }
 }
*/
}
###################################################################
# Write to file internal and external ips
###################################################################
resource "local_file" "inventory" {
  content = "[external_ips]\n${join("\n",google_compute_instance.mpi.*.network_interface.0.access_config.0.nat_ip)}"
  filename = "${path.module}/../ansible/inventory"
}
resource "local_file" "mpi_hostfile" {
  content = templatefile("${path.module}/mpi_hostfile.tmpl",{ip_addrs = join(",", google_compute_instance.mpi.*.network_interface.0.network_ip)})
  filename = "../multivm_container_files/mpi_hostfile"
}
resource "local_file" "internal_ips" {
  content = "[internal_ips]\n${join("\n",google_compute_instance.mpi.*.network_interface.0.network_ip)}\n\n[hosts]\n${local_file.mpi_hostfile.content}"
  filename = "${path.module}/../ansible/internal_ips"
}
resource "local_file" "ssh_config" {
  content = templatefile("${path.module}/ssh_configfile.tmpl",{ip_addrs = join(",", google_compute_instance.mpi.*.network_interface.0.network_ip), port = "2222", user = "nixuser"})
  filename = "../multivm_container_files/ssh_configfile"
}
###################################################################
# Ansible Script for adding host files 
###################################################################
resource "null_resource" "default" {
  triggers = {
    "after" = local_file.ssh_config.id
  }
  connection {
    host = element(google_compute_instance.mpi.*.network_interface.0.access_config.0.nat_ip, 0)
  }
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${path.module}/../ansible/inventory' -i '${path.module}/../ansible/internal_ips' -u '${var.USER}' --private-key '${var.PRIVATE_KEY}' --extra-vars 'user='${var.USER}'' ../ansible/DockerMPI.yaml"
  }
 depends_on = [local_file.inventory, google_compute_instance.mpi]
}

