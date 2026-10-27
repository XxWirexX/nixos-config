# Config Hyprland (home-manager) — base minimale à personnaliser
{ config, pkgs, ... }:

{
  # Outils de base autour de Hyprland
  home.packages = with pkgs; [
    kitty          # terminal
    fuzzel         # lanceur d'applis
    waybar         # barre
    mako           # notifications
    hyprpaper      # fond d'écran
    hyprlock       # écran de verrouillage
    grim slurp     # captures d'écran
    wl-clipboard   # presse-papiers
    brightnessctl  # luminosité
    playerctl      # contrôle média
  ];

  # Montage automatique des clés USB / disques externes (Plasma le fait tout seul,
  # pas Hyprland). Icône dans la barre + notification à l'insertion.
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "auto";
  };

  wayland.windowManager.hyprland = {
    enable = true;
    # Hyprland est installé côté système (programs.hyprland dans configuration.nix),
    # home-manager ne gère ici que la config
    package = null;
    portalPackage = null;
    systemd.enable = false; # désactivé : c'est UWSM (côté système) qui gère la session

    # Config au format hyprlang (hyprland.conf). Lua est le nouveau format par défaut,
    # hyprlang reste supporté (déprécié) : à migrer en Lua lors de la perso des dotfiles
    configType = "hyprlang";

    settings = {
      "$mod" = "SUPER";
      "$terminal" = "kitty";
      "$menu" = "fuzzel";

      # Tous les écrans : résolution préférée, placés automatiquement
      monitor = [ ",preferred,auto,1" ];

      exec-once = [
        "waybar"
        "mako"
      ];

      input = {
        kb_layout = "fr";
        follow_mouse = 1;
        touchpad.natural_scroll = true;
      };

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        layout = "dwindle";
      };

      decoration.rounding = 8;

      bind = [
        "$mod, Return, exec, $terminal"
        "$mod, D, exec, $menu"
        "$mod, Q, killactive"
        "$mod SHIFT, M, exit"
        "$mod, V, togglefloating"
        "$mod, F, fullscreen"
        "$mod, L, exec, hyprlock"
        ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"

        # Focus avec les flèches
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
      ]
      # Workspaces 1 à 9 : on utilise les keycodes (code:10 à 18) pour que ça
      # marche en AZERTY, où les chiffres sont sous & é " ' ( - è _ ç
      ++ builtins.concatLists (builtins.genList (i:
        let ws = toString (i + 1); code = toString (i + 10);
        in [
          "$mod, code:${code}, workspace, ${ws}"
          "$mod SHIFT, code:${code}, movetoworkspace, ${ws}"
        ]) 9);

      # Déplacer / redimensionner à la souris
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # Touches multimédia (fonctionnent même écran verrouillé)
      bindel = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86MonBrightnessUp, exec, brightnessctl s 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl s 5%-"
      ];
      bindl = [
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioPlay, exec, playerctl play-pause"
      ];
    };
  };
}
