FROM nix_alpine_openmpi:75ac746a05cfe14d79fa992f5b36285d19c1a39d
USER root

RUN passwd -d nixuser
# RUN echo "PermitUserEnvironment yes" >> /etc/ssh/sshd_config
RUN echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
ADD ssh_configfile /home/nixuser/.ssh/config
RUN chown nixuser:nixuser /home/nixuser/.ssh/config
RUN chmod 600 /home/nixuser/.ssh/config
ADD mpi_hostfile /home/nixuser/mpi_hostfile

# make mpi and orted executable symlinks on path
RUN for i in $(ls /nixenv/nixuser/.nix-profile/bin) ; do ln -s /nixenv/nixuser/.nix-profile/bin/"$i" /usr/bin ; done
RUN sed -i 's|^nixuser.*|nixuser:x:1000:1000::/home/nixuser:/nixenv/nixuser/.nix-profile/bin/bash|' /etc/passwd

USER nixuser
ADD mpi_ring_c.c /home/nixuser/mpi_ring_c.c
RUN mpicc /home/nixuser/mpi_ring_c.c -o /home/nixuser/mpi_ring && chmod +x /home/nixuser/mpi_ring

USER root
RUN echo "must have last USER directive root for entrypoint to run properly"
EXPOSE 2222
