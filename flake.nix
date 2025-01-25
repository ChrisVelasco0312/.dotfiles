{
 description = "The One And Only NixOS Config"; 
 
 inputs = {
   # Nixpkgs
   nixpkgs.url = "github:NixOS/nixpkgs/release-24.11";

   # Home manager
   home-manager.url = "github:nix-community/home-manager/release-24.11";
   home-manager.inputs.nixpkgs.follows = "nixpkgs";

   # Neovim plugins:
   plugin-lualine.url = "github:nvim-lualine/lualine.nvim";
   plugin-lualine.flake = false;

   #ghostty
   ghostty.url = "github:ghostty-org/ghostty";


   nixd.url = "github:nix-community/nixd";
   # Hardware
   hardware.url = "github:nixos/nixos-hardware";
 };

  outputs = { self, nixpkgs, nixd, home-manager, ghostty, ... }@inputs:
    let 
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
       nixosConfigurations = {
         nixos = nixpkgs.lib.nixosSystem {
           specialArgs = { inherit inputs; }; 
           modules = [ 
           {
             nixpkgs.overlays = [ nixd.overlays.default ];
             environment.systemPackages = with pkgs; [
               nixd
               ghostty.packages.x86_64-linux.default
             ];
           }
             ./nixos/configuration.nix
             ./nixos/hyprland.nix
             ./nixos/brave.nix
           ];
         };
       };

       homeConfigurations = {
         "cavelasco@nixos" = home-manager.lib.homeManagerConfiguration {
           pkgs = nixpkgs.legacyPackages.x86_64-linux; 
           extraSpecialArgs = { inherit inputs; }; 
           modules = [  ./home-manager/home.nix ];
         };
       };
      
      devShells.x86_64-linux.default = (import ./node-shells/shell.nix {inherit pkgs; });
     };
}
