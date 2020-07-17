Testing Results
===
This directory is automatically populated with the results of running HPL benchmarks via ansible-terraform on GCP. The naming convention is [execution type]-[machine-type]-[number of VMs]-[other information], but feel free to change that according to your needs/preferences.

When running HPL, the output is being piped from a container running on the master VM to some `out.txt` on said VM. Then Terraform uses `scp` to copy it to the local container, where it is renamed according to the `RUNNAME` parameter of [build.sh](../build.sh), and finally that gets copied to this folder via `docker cp` in the build script.

Each file from successful runs contains the output of HPL. For each task in HPL.dat, there will be a line with that gives the values of N, NB, P, Q, Time, and Gflops.
