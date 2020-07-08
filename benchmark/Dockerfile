#FROM cornellcac/nix_alpine_base:2cd324f48c57f66d476a7894c6a957a78e49b116
#FROM jefflantz/nix_alpine_base_2.3.6:e808888a49241a975cb6ec6f37b2bc67f74ea846_testing
FROM jefflantz/nix_alpine_base_2.3.6:148ef8f386bd8b4e8c5a084eb522eb2366bc4f88
#TODO: volume mount the private key

USER $nixuser 
RUN mkdir $HOME/.ssh/ && chmod 700 $HOME/.ssh/  
ARG SSH_PRIVATE_KEY
ARG SSH_PUBLIC_KEY
RUN echo "$SSH_PRIVATE_KEY" > $HOME/.ssh/id_rsa && chmod 600 $HOME/.ssh/id_rsa
RUN echo "$SSH_PUBLIC_KEY" >$HOME/.ssh/id_rsa.pub && chmod 644 $HOME/.ssh/id_rsa.pub
#FROM cornellcac/nix_alpine_base:2cd324f48c57f66d476a7894c6a957a78e49b116

#Adding ansible and terraform files 

COPY terraform-multivm $HOME/terraform-multivm
COPY multivm_container_files $HOME/multivm_container_files
COPY nix_gcp $HOME/nix_gcp
COPY ansible $HOME/ansible
USER root 
#RUN echo $nixuser
RUN chown -R $nixuser:$nixuser $HOME/terraform-multivm \ 
  $HOME/multivm_container_files \
  $HOME/nix_gcp \
  $HOME/ansible
#RUN ls -al $HOME/terraform-multivm 
#RUN ls -al $HOME/multivm_container_files
#RUN ls -al $HOME/nix_gcp
USER $nixuser
RUN nix-shell /home/nixuser/nix_gcp/default.nix --show-trace --run $HOME/nix_gcp/terraform.sh
#RUN nix-shell $HOME/nix_gcp/default.nix --show-trace
