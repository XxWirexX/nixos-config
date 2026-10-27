{ config, pkgs, ... }:

{
  imports = [
    ./impasto.nix
  ];

  home.username = "wire";
  home.homeDirectory = "/home/wire";

  # Comme system.stateVersion : ne pas changer après coup
  home.stateVersion = "26.05";

  # Paquets de ton utilisateur (pas besoin de sudo pour les gérer)
  home.packages = with pkgs; [
    fastfetch
    btop
    tree
  ];

  # Git géré par home-manager (génère ~/.config/git/config)
  programs.git = {
    enable = true;
    settings = {
      user.name = "XxWirexX";
      user.email = "keybosslebg@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  # GitHub CLI + utilisation de gh comme gestionnaire d'identifiants pour Git
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
    settings.git_protocol = "ssh";
  };

  # Bash avec quelques raccourcis
  programs.bash = {
    enable = true;
    shellAliases = {
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config#nixos";
      update = "nix flake update --flake ~/nixos-config";
      nconf = "cd ~/nixos-config";
    };
  };

  # Laisse home-manager se gérer lui-même
  programs.home-manager.enable = true;
}
