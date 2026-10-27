{
  description = "Config NixOS de Wire";

  inputs = {
    # Version de nixpkgs utilisée pour tout le système (même branche que l'install)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Hyprland depuis son flake officiel, épinglé sur une release
    # (nixpkgs 26.05 n'a que la 0.55 ; Impasto demande la 0.56+).
    # Pas de "follows" sur nixpkgs : sinon le cache binaire ne sert plus et tout se recompile.
    hyprland.url = "github:hyprwm/Hyprland/v0.56.2";

    # Quickshell (le moteur du shell d'Impasto), en 0.3.2 : nixpkgs 26.05 n'a que la 0.3.0.
    # Construit contre notre nixpkgs pour partager le même Qt que le reste du système.
    quickshell = {
      url = "github:quickshell-mirror/quickshell/v0.3.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Ton fork d'Impasto, pour ses fichiers SYSTÈME (écran de connexion, avatar).
    # Le reste (shell, config Hyprland) est lu directement dans ~/impasto.
    # Après une modif de system/ dans le fork : nix flake update impasto
    impasto = {
      url = "github:XxWirexX/impasto";
      flake = false;
    };

    # Zen Browser (pas dans nixpkgs) ; Impasto lui applique ta palette
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # home-manager : gère ton home (dotfiles, programmes utilisateur)
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs"; # utilise le même nixpkgs que le système
    };
  };

  outputs = { self, nixpkgs, home-manager, hyprland, ... }@inputs: {
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
