# Impasto (le rice : island, launcher, lock…) — partie SYSTÈME
# Traduction en Nix de packages/pacman.txt et aur.txt du fork XxWirexX/impasto.
# Les paquets sont installés côté système : le fork cherche ses données dans
# /run/current-system/sw (icônes, emoji, xkb, agents…).
{ config, pkgs, inputs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
  quickshell = inputs.quickshell.packages.${system}.default;

  # Python des scripts du shell. Les modules en plus servent aux effets caméra
  # (camera.py) ; les autres scripts n'utilisent que la bibliothèque standard.
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
    fzf zoxide fastfetch btop cava yazi imv mpv ffmpeg

    # ── Fichiers ───────────────────────────────────────────────────────────
    nautilus              # Super+E
    ffmpegthumbnailer

    # ── Machines virtuelles (Super+Maj+M) ──────────────────────────────────
    quickemu              # quickemu + quickget (télécharge les ISO)
    spice-gtk             # spicy : affiche la VM dans une fenêtre
    qemu                  # qemu-img (taille des disques)

    # ── Agents ─────────────────────────────────────────────────────────────
    kdePackages.polkit-kde-agent-1 # secours si le shell ne peut pas être l'agent polkit
    kdePackages.kwallet-pam        # pam_kwallet_init, lancé par l'autostart Hyprland
  ];

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
