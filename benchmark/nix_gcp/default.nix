with import <nixpkgs> {}; 
let 
  pkgs = import <nixpkgs> {}; 
in 
stdenv.mkDerivation {
  name = "gcpBuildEnv"; 
  buildInputs = [
  nix 
  bash 
  
  # terraform and ansible required packages
  openssh
  ansible_2_7 
  terraform
  ];
  src = null; 
}
