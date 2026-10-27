{
  description = "Config NixOS de Wire";

  inputs = {
    # Version de nixpkgs utilisée pour tout le système (même branche que l'install)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    # "nixos" = ton hostname : nixos-rebuild choisit cette config automatiquement
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
      ];
    };
  };
}
