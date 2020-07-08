CONTAINER=$1
docker start $CONTAINER
docker exec -t $CONTAINER nix-shell /home/nixuser/nix_gcp/default.nix --run 'cd /home/nixuser/terraform-multivm; terraform destroy --auto-approve'
