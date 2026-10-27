# Impasto (le rice : island, launcher, lock…) — partie SYSTÈME
# Traduction en Nix de packages/pacman.txt et aur.txt du fork XxWirexX/impasto.
# Les paquets sont installés côté système : le fork cherche ses données dans
# /run/current-system/sw (icônes, emoji, xkb, agents…).
{ config, pkgs, inputs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
  quickshell = inputs.quickshell.packages.${system}.default;
in
{
  environment.systemPackages = with pkgs; [
    # ── Le bureau ──────────────────────────────────────────────────────────
    quickshell            # le shell : barre, island, lock, notifications (qs)
    awww                  # fond d'écran
    imagemagick           # palette tirée du fond d'écran
    python3               # tous les scripts du shell (stdlib uniquement)
    git
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

    # ── Programmes terminal ────────────────────────────────────────────────
    fzf zoxide fastfetch btop cava yazi imv mpv ffmpeg

    # ── Fichiers ───────────────────────────────────────────────────────────
    nautilus              # Super+E
    ffmpegthumbnailer

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

  # Services que les tuiles du centre de contrôle utilisent
  services.upower.enable = true;            # batterie
  services.power-profiles-daemon.enable = true;
  hardware.bluetooth.enable = true;
  services.gvfs.enable = true;              # corbeille, montages (Nautilus)
}
