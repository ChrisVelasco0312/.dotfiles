{
 description = "The One And Only NixOS Config"; 

 inputs = {
   # Nixpkgs
   nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

   # Home manager
   home-manager.url = "github:nix-community/home-manager";
   home-manager.inputs.nixpkgs.follows = "nixpkgs";

   # Hardware
   hardware.url = "github:nixos/nixos-hardware";

   #hyprland
   hyprland.url = "github:hyprwm/Hyprland";
 };

 outputs = { self, nixpkgs, home-manager, hyprland, ... }@inputs: {
   nixosConfigurations = {
     nixos = nixpkgs.lib.nixosSystem {
       specialArgs = { inherit inputs; }; 
       modules = [ 
         ./nixos/configuration.nix
       ];
     };
   };

   homeConfigurations = {
     "cavelasco@nixos" = home-manager.lib.homeManagerConfiguration {
       pkgs = nixpkgs.legacyPackages.x86_64-linux; 
       extraSpecialArgs = { inherit inputs; }; 
       modules = [ 
           ./home-manager/home.nix 
	   hyprland.nixosModule.default
	   { programs.hyprland.enable = true; }
           ];
     };
   };
 };
}
