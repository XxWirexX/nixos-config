# Impasto (le rice : island, launcher, lock…) — partie SYSTÈME
# Traduction en Nix de packages/pacman.txt et aur.txt du fork XxWirexX/impasto.
# Les paquets sont installés côté système : le fork cherche ses données dans
# /run/current-system/sw (icônes, emoji, xkb, agents…).
{ config, pkgs, inputs, hyprPkgs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
  quickshell = inputs.quickshell.packages.${system}.default;

  # Python des scripts du shell. Les modules en plus servent aux effets caméra
  # (camera.py) ; les autres scripts n'utilisent que la bibliothèque standard.
  # Plugins Hyprland, construits contre CE Hyprland (0.56.2) et son compilateur :
  # un plugin compilé pour une autre version est refusé au chargement.
  hyprPlugins = with hyprPkgs.hyprlandPlugins; [
    (hyprPkgs.callPackage ./pkgs/hypr-dynamic-cursors.nix { inherit mkHyprlandPlugin; })
    (hyprPkgs.callPackage ./pkgs/hyprglass.nix { inherit mkHyprlandPlugin; })
  ];

  impastoSystem = pkgs.callPackage ./pkgs/impasto-system.nix { src = inputs.impasto; };

  python = pkgs.python3.withPackages (ps: [
    ps.numpy
    ps.opencv4
    ps.pillow
    (ps.callPackage ./pkgs/mediapipe.nix { })
  ]);
in
{
  environment.systemPackages = with pkgs; [
    # ── Le bureau ──────────────────────────────────────────────────────────
    quickshell            # le shell : barre, island, lock, notifications (qs)
    awww                  # fond d'écran
    imagemagick           # palette tirée du fond d'écran
    python                # scripts du shell (+ numpy, opencv, mediapipe pour la caméra)
    git
    curl                  # ./setup camera télécharge les modèles avec
    grim                  # captures, et la photo de l'écran de verrouillage
    wl-clipboard          # copier/coller + historique
    gtk3                  # gtk-launch : le launcher lance les applis avec
    libnotify             # notify-send
    fontconfig            # fc-list
    playerctl             # touches média
    xdg-user-dirs
    xdg-utils
    qt6Packages.qt6ct     # thème Qt (palette appliquée aux applis Qt)
    kdePackages.qtmultimedia # aperçu caméra

    # ── Données que le shell lit ───────────────────────────────────────────
    papirus-icon-theme
    whitesur-icon-theme   # icônes d'applis du shell
    bibata-cursors        # curseur
    unicode-emoji         # emoji dans le launcher
    cldr-annotations      # leurs noms, dans toutes les langues
    isocodes              # noms de pays (drapeaux)

    # ── Terminal ───────────────────────────────────────────────────────────
    kitty
    starship

    # ── Contrôles rapides ──────────────────────────────────────────────────
    brightnessctl         # luminosité de l'écran du portable
    ddcutil               # luminosité d'un écran externe
    hyprsunset            # lumière nocturne
    hyprpicker            # pipette à couleurs
    hyprshutdown          # Super+Maj+E
    hyprcursor

    # ── Captures et enregistrement ─────────────────────────────────────────
    satty                 # annotation
    tesseract             # lire le texte d'une zone (OCR)
    wf-recorder
    wl-screenrec          # enregistrement via le GPU, essayé en premier
    pulseaudio            # pactl (trouve la sortie audio à enregistrer)
    v4l-utils             # v4l2-ctl : trouve la webcam (effets caméra)

    # ── Programmes terminal ────────────────────────────────────────────────
    fzf zoxide fnm fastfetch btop cava yazi imv mpv ffmpeg
    unimatrix cbonsai tty-clock lavat   # alias matrix, bonsai, clock, lava du .zshrc

    # ── Fichiers ───────────────────────────────────────────────────────────
    nautilus              # Super+E
    ffmpegthumbnailer

    # ── Machines virtuelles (Super+Maj+M) ──────────────────────────────────
    quickemu              # quickemu + quickget (télécharge les ISO)
    spice-gtk             # spicy : affiche la VM dans une fenêtre
    qemu                  # qemu-img (taille des disques)

    # ── Fonds d'écran animés ───────────────────────────────────────────────
    mpvpaper              # joue une vidéo en fond d'écran

    # ── Applis aux couleurs de la palette ──────────────────────────────────
    # (premier thème : ./setup vscodium, ./setup vesktop, ./setup spotify)
    vscodium
    vesktop               # Discord
    spicetify-cli         # thème Spotify ; Spotify lui-même en Flatpak (voir plus bas)
    inputs.zen-browser.packages.${system}.default

    # ── Neovim d'Impasto (~/.config/nvim) et ce que sa config utilise ──────
    neovim
    tree-sitter gcc       # compile les parsers de coloration
    ripgrep fd            # recherche de texte et de fichiers
    lua-language-server basedpyright ruff bash-language-server

    # ── Agents ─────────────────────────────────────────────────────────────
    kdePackages.polkit-kde-agent-1 # secours si le shell ne peut pas être l'agent polkit
    kdePackages.kwallet-pam        # pam_kwallet_init, lancé par l'autostart Hyprland
  ]
  # Plugins -> /run/current-system/sw/lib/lib*.so, chargés par modules/plugins.lua du fork
  ++ hyprPlugins
  # Thème SDDM, script d'avatar et sa règle polkit
  ++ [ impastoSystem ];

  # ── Écran de connexion (SDDM) ────────────────────────────────────────────
  # Sur Arch : /etc/sddm.conf.d/10-impasto.conf, écrit par ./setup system
  services.displayManager.sddm = {
    theme = "impasto";
    settings = {
      # Le thème lit la batterie dans /sys (pas d'UPower au login) : Qt 6
      # l'interdit sans cette variable. On garde celle du greeter Wayland.
      General.GreeterEnvironment = "QT_WAYLAND_SHELL_INTEGRATION=layer-shell,QML_XHR_ALLOW_FILE_READ=1";
      # Photos de compte, partagées avec l'écran de verrouillage d'Impasto
      Theme.FacesDir = "/var/lib/impasto/faces";
    };
  };
  systemd.tmpfiles.rules = [ "d /var/lib/impasto/faces 0755 root root -" ];

  # Bouton power : ouvre le menu de session d'Impasto au lieu d'éteindre
  # (un appui long éteint toujours, géré par le firmware)
  services.logind.settings.Login.HandlePowerKey = "ignore";

  # ── Spotify en Flatpak ──────────────────────────────────────────────────
  # spicetify doit modifier les fichiers de Spotify pour appliquer la palette :
  # impossible dans /nix/store (lecture seule), possible dans un Flatpak
  # installé pour l'utilisateur. Une fois :
  #   flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  #   flatpak install --user flathub com.spotify.Client
  services.flatpak.enable = true;

  # ── Écran de démarrage (Plymouth) ────────────────────────────────────────
  # Sur Arch : ./setup splash (mkinitcpio + argument "splash")
  boot.plymouth = {
    enable = true;
    theme = "impasto";
    themePackages = [ impastoSystem ];
  };
  # Démarrage silencieux : l'animation au lieu des lignes de texte
  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;
  boot.kernelParams = [ "quiet" "splash" "udev.log_level=3" "rd.udev.log_level=3" ];
  # Le pilote de l'écran du portable (iGPU Intel) dès le début du boot,
  # pour que l'animation s'affiche tout de suite et en pleine résolution
  boot.initrd.kernelModules = [ "i915" ];

  # ── zsh, le shell d'Impasto ──────────────────────────────────────────────
  # Le .zshrc (oh-my-zsh, starship, fzf, zoxide…) vient du fork, via impasto.nix
  programs.zsh = {
    enable = true;
    enableGlobalCompInit = false; # oh-my-zsh le fait déjà, une fois suffit
  };
  users.users.wire.shell = pkgs.zsh;

  # Luminosité des écrans externes (ddcutil, via DDC/CI)
  hardware.i2c.enable = true;

  fonts.packages = with pkgs; [
    inter                       # police du shell
    nerd-fonts.jetbrains-mono   # terminal + glyphes de la barre
    adwaita-fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  # Rend ces dossiers visibles dans /run/current-system/sw, où le fork les cherche
  environment.pathsToLink = [
    "/libexec"          # pam_kwallet_init, polkit-kde-authentication-agent-1
    "/share/unicode"    # emoji-test.txt, annotations CLDR
    "/share/iso-codes"
    "/share/X11"        # règles xkb (liste des dispositions clavier)
    "/share/icons"
  ];

  # ── Effets caméra (Super+Maj+W) ──────────────────────────────────────────
  # Caméra virtuelle "impasto camera", que camera.py alimente avec la webcam
  # filtrée, et que les applis d'appel voient comme une webcam.
  # (Sur Arch : /etc/modprobe.d et /etc/modules-load.d écrits par ./setup camera)
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModprobeConfig = ''
    options v4l2loopback video_nr=10 card_label="impasto camera" exclusive_caps=1
  '';

  # Services que les tuiles du centre de contrôle utilisent
  services.upower.enable = true;            # batterie
  services.power-profiles-daemon.enable = true;
  hardware.bluetooth.enable = true;
  services.gvfs.enable = true;              # corbeille, montages (Nautilus)
}
