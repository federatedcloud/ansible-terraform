docker start terraform_ansible_container
docker exec -t terraform_ansible_container nix-shell /home/nixuser/nix_gcp/default.nix --run 'cd /home/nixuser/terraform-multivm; terraform destroy --auto-approve'
