{
  description = "Config NixOS de Wire";

  inputs = {
    # Version de nixpkgs utilisée pour tout le système (même branche que l'install)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # home-manager : gère ton home (dotfiles, programmes utilisateur)
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs"; # utilise le même nixpkgs que le système
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    # "nixos" = ton hostname : nixos-rebuild choisit cette config automatiquement
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;   # même pkgs (et allowUnfree) que le système
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup"; # renomme un fichier existant au lieu d'échouer
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.wire = import ./home.nix;
        }
      ];
    };
  };
}
