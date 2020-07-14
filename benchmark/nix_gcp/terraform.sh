cd $HOME/terraform-multivm
terraform init
terraform apply -auto-approve -var 'RUNNAME=$RUNNAME'
