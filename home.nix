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
    claude-code   # commande "claude" ; remplit aussi le widget d'usage d'Impasto
    codex         # Codex (OpenAI) ; son widget d'usage aussi
    google-chrome
    obsidian      # notes en Markdown (unfree, OK grâce à allowUnfree)
    jetbrains.idea
    nodejs
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

  # direnv : active automatiquement le devShell d'un projet (flake.nix + .envrc) au `cd`
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };

  # GitHub CLI + utilisation de gh comme gestionnaire d'identifiants pour Git
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
    settings.git_protocol = "ssh";
  };

  # Alias partagés : bash (ici) et zsh (~/.zshrc.local, écrit par impasto.nix)
  home.shellAliases = {
    rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config#nixos";
    update = "nix flake update --flake ~/nixos-config";
    nconf = "cd ~/nixos-config";
  };
  programs.bash.enable = true;

  # Firefox comme navigateur par défaut (liens, xdg-open, fichiers HTML)
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
    };
  };
  home.sessionVariables.BROWSER = "firefox";

  # Laisse home-manager se gérer lui-même
  programs.home-manager.enable = true;
}
