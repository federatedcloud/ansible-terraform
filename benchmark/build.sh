#!/bin/sh
docker build -t nix_build_gcp_image \
  --build-arg SSH_PRIVATE_KEY="$(cat ${SSH_PRIVATE_KEY_LOCATION:="$HOME/.ssh/id_rsa"})" \
  --build-arg SSH_PUBLIC_KEY="$(cat ${SSH_PUBLIC_KEY_LOCATION:="$HOME/.ssh/id_rsa.pub"})" \
  .
docker stop nix_build_gcp_image
docker rm nix_build_gcp_image
docker run --name terraform_ansible_container nix_build_gcp_image sleep 1000 &
