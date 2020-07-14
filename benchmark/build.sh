#!/bin/sh
RUNNAME=$1
docker build -t nix_build_gcp_image \
  --build-arg SSH_PRIVATE_KEY="$(cat ${SSH_PRIVATE_KEY_LOCATION:="$HOME/.ssh/id_rsa"})" \
  --build-arg SSH_PUBLIC_KEY="$(cat ${SSH_PUBLIC_KEY_LOCATION:="$HOME/.ssh/id_rsa.pub"})" \
  --build-arg RUNNAME=$RUNNAME \
  .
docker stop terraform_ansible_container
docker rm terraform_ansible_container
docker run --name terraform_ansible_container nix_build_gcp_image sleep 1000 &
sleep 10
docker cp terraform_ansible_container:/home/nixuser/$RUNNAME.txt hpl-results
