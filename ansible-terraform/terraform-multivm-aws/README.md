#  Terraform, Ansible, AWS
The following Terraform and Ansible scripts allow for the creation of an openmpi multi-vm cluster on AWS. All instances will run ping, ssh, mpi hello, and mpi_ring. TODO: Finally a single instance will run lake_problem_dps on all of the instances.     
## Dependencies and configurations
To get started, the terraform package (version 0.11) and ansible package (2.7.6+) will need to be installed locally. Terraform will need to have access to GCP by using json credentials files from [https://console.cloud.google.com/apis/credentials/serviceaccountkey](https://console.cloud.google.com/apis/credentials/serviceaccountkey). 
To get started with aws, the pip3 package and aws-cli will need to be install locally. pip3 is needed to install aws-cli as per [https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html). This will create the credentials located in $HOME/.aws/ which will be used by terraform. After installed aws-cli, configure it by typing the command. 
```
aws configure
```
Alternatively, you can create the aws credentials directory manually. The credential file is named credentials and its contents are described below. 
```
[default]
aws_access_key_id = YOURACCESSKEYHERE
aws_secret_access_key = youraccesskeyhere
```
All the parameters for setting up the instances are provided in the variables.tf file. It is important to note that the private and public keys will be used to access the created instance. A bitbucket private key is required to download the Borg repository which will be used in lake_problem_dps. 
## Creation and provisioning of instances
The following steps detail how the instances are created and configured. These steps are applies automatically when calling the terraform scripts and do not need to be repeated. 
1. Terraform first creates a new centos7 instance in your AWS account. It will set up a GCP network and subnetwork with a internal ip address range of 10.0.0.0/16. 
2. Ansible installs the following packages in the centos7 instance (shell equivalent).
  ```
    sudo yum install yum-utils \ git \ device-mapper-persistent-data \ lvm2
    sudo yum-config-manager \ --add-repo \ https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install docker-ce
    sudo systemctl start docker
    sudo groupadd docker
    sudo usermod -aG docker $USER
    sudo yum install epel-release \ python-pip \ docker-compose
  ```
3. Ansible resets connection (to update docker) and installs Lake_Problem_DPS in the centos7 instance
  ```
    git clone https://github.com/federatedcloud/Lake_Problem_DPS.git
    cd $HOME/Lake_Problem_DPS
    BITBUCKET_SSH_KEY=${HOME}/tempkey source docker-compose-openmpi.sh up --scale mpi_head=1 --scale mpi_node=3 </dev/null >/dev/null 2>&1 &
  ``` 
4. Ansible sleeps for 300 seconds to let the image build then stops all containers
5. Terraform then creates a snapshot of the instance. Terraform creates a disk from the snapshot. Finally terraform creates a new image from the disk. N instances will be created from this image (name mpi0 to mpiN). ssh_config and mpi_hostfile are generated (which will be needed to run openmpi). 
6. Ansible exports the directory`multivm_container_files to the instances. The directory contains mpi_ring, hostfile, config_file, and Dockerfile
7. A new docker image and container is created from the dockerfile
  ```
    cd $HOME/multivm_container_files
    docker build -t lake_problem_multivm .
    docker rm -f nix_alpine_container
    docker run -p 2222:2222 --network host --name nix_alpine_container lake_problem_multivm:latest sleep 10000 &
  ```
8. Run ping, ssh, mpi_hello, and mpi_ring tests
  ```
    docker exec -u 0 nix_alpine_container ping -c 5 -t 10 $ip_addresses
    docker exec -u nixuser nix_alpine_container bash -c 'ssh -o ConnectTimeout=10 -i ${HOME}/.ssh/id_rsa $ip_addresses echo && hostname && echo || echo || echo
    docker exec -u nixuser nix_alpine_container /bin/sh -c 'mpirun -d --hostfile /home/nix    user/mpi_hostfile --mca btl self,tcp --mca btl_tcp_if_include eth0 hostname
    docker exec -u nixuser nix_alpine_container /bin/sh -c 'mpirun -d --hostfile /home/nix    user/mpi_hostfile --mca btl self,tcp --mca btl_tcp_if_include eth0 /home/nixuser/mpi_ring
  ```
9. TODO: run lake problem
