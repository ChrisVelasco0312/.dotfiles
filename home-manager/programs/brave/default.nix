{
  # config,
  # lib,
  pkgs,
  # flake-inputs,
  ...
}:  
{
  programs.chromium = {
    enable = true;
    package = pkgs.brave;
    extensions = [
      "dbepggeogbaibhgnhhndojpepiihcmeb" #vimium
      "nngceckbapebfimnlniiiahkandclblb" #bitwarden pass manager
      "cofdbpoegempjloogbagkncekinflcnj" #DeepL translator
    ];
  };
}

