#  Terraform, Ansible, GCP
The following Terraform and Ansible scripts allow for the creation of an openmpi multi-vm cluster on GCP. All instances will run ping, ssh, mpi hello, and mpi_ring, and then a single instance will run HPL.
## Dependencies and configurations
To get started, the terraform package (version 0.12) and ansible package (2.7.6+) will need to be downloaded locally. Terraform will need to have access to GCP by using json credentials files from [https://console.cloud.google.com/apis/credentials/serviceaccountkey](https://console.cloud.google.com/apis/credentials/serviceaccountkey). 
All the parameters for setting up the instances are provided in the variables.tf and terraform.tfvars files. It is important to note that the private and public keys will be used to access the created instance. You **must** add your IP range to the [list of accepted ssh sources](./main.tf#L79). One way to find your IP is to run `dig +short myip.opendns.com @resolver1.opendns.com`. Using a CIDR of `x.y.0.0/16` (where `x`, `y` match your IP) is likely good enough without introducing severe secruity risks.
## Best Practices in Use
 - Set values for variables in [terraform.tfvars](./terraform.tfvars) rather than [variables.tf](./variables.tf).
   - If using a region other than us-east4, refer to the [GCP VPC network IP range table](https://cloud.google.com/vpc/docs/vpc#ip-ranges) and set the [tcp allowed range](https://github.com/federatedcloud/ansible-terraform/blob/aae06e77a58edd59ee5b3fe1b9a4678415b5880b/benchmark/terraform-multivm/main.tf#L91).
 - The image/containers built are somewhat large (~1.5 GB) so ensure you have space in your root directory. Careful use of `docker [container | image] prune`, `docker rm`, and/or `docker rmi` is recommended.
 - Resources in GCP with the same name will cause overlap, so check for overlap before running the code.
   - `./destroy.sh <container-name>` will remove the gcp resources created in your last run. If the run failed at some point, it will still remove most gcp resources, but you may need to employ other methods such as the Cloud Console to deal with the rest.
 - Before each run, ensure that the number of instances and machine type in [terraform.tfvars](./terraform.tfvars) match the mpi runscript in [HPL.yaml](../ansible/HPL.yaml) and the [HPL.dat](../multivm-container-files/HPL.dat) file used.
## Creation and provisioning of instances
The following steps detail how the instances are created and configured. These steps are applied automatically when calling the terraform scripts and do not need to be repeated. 
1. Terraform will first set up a GCP network and subnetwork with a internal ip address range of 10.0.0.0/16. This is a blank network with default firewall rules of allowing all egress and preventing all ingress. A new centos7 will be set up on this network.
2. Ansible installs the following packages in the centos7 instance (shell equivalent).
  ```bash
    sudo yum install yum-utils \ git \ device-mapper-persistent-data \ lvm2
    sudo yum-config-manager \ --add-repo \ https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install docker-ce
    sudo systemctl start docker
    sudo groupadd docker
    sudo usermod -aG docker $USER
    sudo yum install epel-release \ python-pip \ docker-compose \ htop
  ```
3. Ansible resets connection (to update docker) and installs [docker-nix-mpi-benchmarks](https://github.com/federatedcloud/docker-nix-mpi-benchmarks) in the centos7 instance
  ```bash
    git clone https://github.com/federatedcloud/docker-nix-mpi-benchmarks.git -b dev
    cd $HOME/docker-mpi-benchmarks
    source build-openmpi.sh
  ``` 
4. Terraform then creates a snapshot of the instance. Terraform creates a disk from the snapshot. Finally terraform creates a new image from the disk. N instances will be created from this image (name mpi0 to mpiN). `ssh_config `and `mpi_hostfile` are generated (which will be needed to run openmpi). 
5. Ansible exports the directory `multivm_container_files` to the instances. The directory contains `mpi_ring`, `hostfile`, `config_file`, and `Dockerfile`
6. A new docker image and container is created from the dockerfile
  ```bash
    cd $HOME/multivm_container_files
    docker build -t docker-nix-mpi-benchmarks .
    docker rm -f nix_alpine_container
    docker run -p 2222:2222 --network host --name nix_alpine_container docker-nix-mpi-benchmarks:latest sleep 10000 &
  ```
8. Run `ping`, `ssh`, `mpi_hello`, and `mpi_ring` tests from each of the VMs
```bash
    docker exec -u 0 nix_alpine_container ping -c 5 -t 10 $ip_addresses
    docker exec -u nixuser nix_alpine_container bash -c 'ssh -o ConnectTimeout=10 -i ${HOME}/.ssh/id_rsa $ip_addresses echo && hostname && echo || echo || echo'
    docker exec -u nixuser nix_alpine_container /bin/sh -c 'mpirun -d --hostfile /home/nixuser/mpi_hostfile --mca btl self,tcp --mca btl_tcp_if_include eth0 hostname'
    docker exec -u nixuser nix_alpine_container /bin/sh -c 'mpirun -d --hostfile /home/nixuser/mpi_hostfile --mca btl self,tcp --mca btl_tcp_if_include eth0 /home/nixuser/mpi_ring'
  ```
9. From exclusively the host VM (by default mpi-instance0), runs HPL.
```bash
    docker exec -u nixuser nix_alpine_container nix-shell dev.nix --run 'cd ~; mpirun -np 6 --hostfile mpi_hostfile --bind-to core --map-by ppr:2:node xhpl
```
