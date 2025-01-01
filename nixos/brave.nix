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
    extensions = [
      "dbepggeogbaibhgnhhndojpepiihcmeb" #vimium
      "nngceckbapebfimnlniiiahkandclblb" #bitwarden pass manager
      "cofdbpoegempjloogbagkncekinflcnj" #DeepL translator
    ];
    defaultSearchProviderSuggestURL = "https://duckduckgo.com";
    defaultSearchProviderSearchURL = "https://duckduckgo.com";
  };
}


