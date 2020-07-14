FROM cornellcac/nix_alpine_base:0f566286984d3565f89262acb3186483832bdae8

USER $nixuser 
RUN mkdir $HOME/.ssh/ && chmod 700 $HOME/.ssh/  
ARG SSH_PRIVATE_KEY
ARG SSH_PUBLIC_KEY
ARG RUNNAME
RUN export RUNNAME=$RUNNAME
RUN echo "$SSH_PRIVATE_KEY" > $HOME/.ssh/id_rsa && chmod 600 $HOME/.ssh/id_rsa
RUN echo "$SSH_PUBLIC_KEY" >$HOME/.ssh/id_rsa.pub && chmod 644 $HOME/.ssh/id_rsa.pub

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
