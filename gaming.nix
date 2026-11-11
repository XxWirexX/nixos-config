{ inputs, ... }:

{
  # ===== Jeux HoYoverse (Genshin Impact) =====
  # An Anime Game Launcher, via le flake aagl-gtk-on-nix.
  imports = [ inputs.aagl.nixosModules.default ];

  programs.anime-game-launcher.enable = true; # Genshin Impact

  # Cache binaire de l'équipe AAGL : évite de recompiler le launcher.
  # (Les listes se fusionnent avec le cache Hyprland déclaré dans configuration.nix.)
  nix.settings.substituters = [ "https://an-anime-team.cachix.org" ];
  nix.settings.trusted-public-keys = [ "an-anime-team.cachix.org-1:nr9QXfYG5tDXIImqxjSXd1b6ymLfGCvviuV8xRPIKPM=" ];
}
