provider "aws" {
  profile    = "default"
  region     = "us-east-2"
}
//finds centos_7
data "aws_ami" "centos_7" {
  most_recent = true
  
  filter {
    name = "name"
    values = ["CentOS Linux 7 x86_64*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["aws-marketplace"]
}
resource "aws_key_pair" "openmpi" {
  key_name = "openmpi-key"
  public_key = "${replace(file(var.PUBLIC_KEY), "\n", "")}"
}
output "debug" {
  value = "${replace(file(var.PUBLIC_KEY), "\n", "")}"
  description = "test"
}
output "ebug" {
  value = "${aws_key_pair.openmpi.key_name}"
  description = "tes2"
}
resource "aws_vpc" "openmpi_cluster" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags {
    Name = "openmpi-cluster"
  }
}
resource "aws_internet_gateway" "openmpi_cluster" {
  vpc_id = "${aws_vpc.openmpi_cluster.id}"
}
resource "aws_subnet" "openmpi_cluster" {
  cidr_block = "10.0.0.0/24"
  vpc_id = "${aws_vpc.openmpi_cluster.id}"
  availability_zone = "us-east-2a"
}
resource "aws_route_table" "openmpi_cluster" {
  vpc_id = "${aws_vpc.openmpi_cluster.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.openmpi_cluster.id}"
  }
}
resource "aws_route_table_association" "subnet-association" {
  subnet_id = "${aws_subnet.openmpi_cluster.id}"
  route_table_id = "${aws_route_table.openmpi_cluster.id}"
}
resource "aws_security_group" "ingress-cornell"   {
  name = "allow-cornell-ssh"
  vpc_id = "${aws_vpc.openmpi_cluster.id}"
  ingress {
    cidr_blocks = ["128.84.0.0/16"]
    from_port = 22
    to_port = 22
    protocol = "tcp"
    description = "cornell access" 
  }
  ingress { 
    cidr_blocks = ["10.0.0.0/16"]
    from_port = 0
    to_port = 65535 
    protocol = "tcp"
    description = "internal access"
  }
  ingress {
    cidr_blocks = ["10.0.0.0/16"]
    from_port = -1 
    to_port = -1
    protocol = "icmp"
    description = "ping"
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "access anywhere from instance"
  }
}
resource "aws_eip" "openmpi_cluster" {
  instance = "${aws_instance.base_vm.id}"
  vpc = true
}
resource "aws_instance" "base_vm" {
  instance_type = "t2.micro"
  ami           = "${data.aws_ami.centos_7.id}" 
  key_name = "${aws_key_pair.openmpi.key_name}"
  security_groups = ["${aws_security_group.ingress-cornell.id}"]
  subnet_id = "${aws_subnet.openmpi_cluster.id}"
  associate_public_ip_address = true
  provisioner "remote-exec" {
    # ensures that a connection is set up
        inline = ["echo"]
    connection {
     type = "ssh"
     user = "${var.USER}"
     private_key = "${file("${var.PRIVATE_KEY}")}"
    }
  }
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${var.USER}@${aws_instance.base_vm.public_ip},' --private-key '${var.PRIVATE_KEY}' ../ansible/CentosPlaybook.yaml --extra-vars 'bitbucket_key='${var.BITBUCKET_KEY}' user='${var.USER}''"
  }
}
resource "aws_ami_from_instance" "openmpi_cluster" {
  name = "openmpi_example" 
  source_instance_id = "${aws_instance.base_vm.id}"
}
resource "aws_instance" "openmpi_cluster" {
  count = "${var.cluster_count}"
  instance_type = "${var.machine_type}"
  ami = "${aws_ami_from_instance.openmpi_cluster.id}"
  key_name = "${aws_key_pair.openmpi.key_name}"
  security_groups = ["${aws_security_group.ingress-cornell.id}"]
  subnet_id = "${aws_subnet.openmpi_cluster.id}"
  associate_public_ip_address = true
  provisioner "remote-exec" {
    # ensures that a connection is set up
        inline = ["echo"]
    connection {
     type = "ssh"
     user = "${var.USER}"
     private_key = "${file("${var.PRIVATE_KEY}")}"
    }
  }
}
data "template_file" "mpi_hostfile" {
  template = "${file("mpi_hostfile.tmpl")}"
  vars {
    ip_addrs = "${join(",",aws_instance.openmpi_cluster.*.private_ip)}"
  }
}
data "template_file" "ssh_configfile" {
  template = "${file("ssh_configfile.tmpl")}"
  vars {
    ip_addrs = "${join(",",aws_instance.openmpi_cluster.*.private_ip)}"
    port = "2222"
    user = "nixuser"
  }
}
resource "local_file" "inventory" {
  content = "[external_ips]\n${join("\n",aws_instance.openmpi_cluster.*.public_ip)}"
  filename = "${path.module}/../ansible/inventory"
}
resource "local_file" "internal_ips" {
  content = "[internal_ips]\n${join("\n",aws_instance.openmpi_cluster.*.private_ip)}\n\n[hosts]\n${data.template_file.mpi_hostfile.rendered}"
  filename = "${path.module}/../ansible/internal_ips"
}
resource "local_file" "mpi_hostfile" {
  content = "${data.template_file.mpi_hostfile.rendered}"
  filename = "../multivm_container_files/mpi_hostfile"
}
resource "local_file" "ssh_config" {
  content = "${data.template_file.ssh_configfile.rendered}"
  filename = "../multivm_container_files/ssh_configfile"
}
resource "null_resource" "default" {
  triggers = {
    "after" = "${local_file.ssh_config.id}"
  }
  connection {
    host = "${aws_instance.openmpi_cluster.*.public_ip}"
  }
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${path.module}/../ansible/inventory' -i '${path.module}/../ansible/internal_ips' -u '${var.USER}' --private-key '${var.PRIVATE_KEY}' --extra-vars 'user='${var.USER}'' ../ansible/DockerMPI.yaml"
  }
}
output "eip_private" {
  value = "${aws_eip.openmpi_cluster.private_ip}"
}
output "eip_public" {
  value = "${aws_eip.openmpi_cluster.public_ip}"
}
output "debug_private" {
  value = "${aws_instance.base_vm.private_ip}" 
}
output "eip_instance" {
  value = "${aws_eip.openmpi_cluster.instance}"
}
output "list_public" {
  value = "${aws_instance.openmpi_cluster.*.private_ip}"
}
output "list_private" {
  value = "${aws_instance.openmpi_cluster.*.public_ip}"
}
