# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, inputs, ... }:

let
  # Paquets Hyprland : le nixpkgs du flake Hyprland + ses overlays.
  # Correctif : Hyprland 0.56.2 exige glaze 7.x (find_package(glaze 7...<8)), mais son
  # nixpkgs a glaze 8.0.0 -> le build plante. On remet glaze 7.7.1 (header-only, sans risque).
  # À retirer quand on passera à une version de Hyprland qui accepte glaze 8.
  hyprPkgs = import inputs.hyprland.inputs.nixpkgs {
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [
      (final: prev: {
        glaze = prev.glaze.overrideAttrs (old: {
          version = "7.7.1";
          src = prev.fetchFromGitHub {
            owner = "stephenberry";
            repo = "glaze";
            tag = "v7.7.1";
            hash = "sha256-CfN2mv1s+yv2HvRLBZhHUHBNfsgRzTT7USNYkkahh8M=";
          };
        });
      })
      # Même assemblage que le flake Hyprland (pkgsFor) : dépendances + Hyprland + portail
      inputs.hyprland.overlays.hyprland-packages
      inputs.hyprland.overlays.hyprland-extras
    ];
  };
in

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./impasto-system.nix
    ];

  # ===== Bootloader : GRUB =====
  # Menu : NixOS / NixOS - All configurations / Windows 11
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev"; # UEFI : pas d'install sur un disque entier
    configurationLimit = 10;
    useOSProber = false; # entrée Windows écrite à la main ci-dessous
    extraEntries = ''
      menuentry "Windows 11" {
        insmod part_gpt
        insmod fat
        search --no-floppy --fs-uuid --set=root 05E7-09E2
        chainloader /EFI/Microsoft/Boot/bootmgfw.efi
      }
    '';
  };

  # ===== Nettoyage automatique des générations =====
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.settings.auto-optimise-store = true;

  # ===== Flakes =====
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Cache binaire de Hyprland : télécharge Hyprland déjà compilé au lieu de le builder
  nix.settings.substituters = [ "https://hyprland.cachix.org" ];
  nix.settings.trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
  i18n.defaultLocale = "fr_FR.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Hyprland, en plus de Plasma (session à choisir dans SDDM)
  # Rend hyprPkgs disponible aux autres modules (impasto-system.nix : plugins)
  _module.args.hyprPkgs = hyprPkgs;

  programs.hyprland = {
    enable = true;
    withUWSM = true; # lancement propre via systemd
    package = hyprPkgs.hyprland;
    portalPackage = hyprPkgs.xdg-desktop-portal-hyprland;
  };
  services.displayManager.sddm.wayland.enable = true;
  security.pam.services.hyprlock = { }; # pour que hyprlock accepte ton mot de passe

  # ===== KDE Connect =====
  # Installe KDE Connect (version Plasma 6) et ouvre les ports 1714-1764 TCP/UDP
  # dans le pare-feu. Le démon se lance via l'autostart XDG (Plasma, et Hyprland via UWSM).
  programs.kdeconnect.enable = true;

  # ===== Docker =====
  # Démon Docker + docker compose (plugin inclus). Démarré à la demande via le socket.
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false; # se lance au premier appel à docker, pas au boot
    autoPrune.enable = true; # nettoie images/conteneurs inutilisés chaque semaine
  };
  services.udisks2.enable = true; # nécessaire pour udiskie (déjà activé par Plasma, mais explicite)

  # ===== Trousseau (KWallet) =====
  # Déverrouillé automatiquement à la connexion via SDDM, pour Plasma ET Hyprland
  security.pam.services.sddm.kwallet = {
    enable = true;
    package = pkgs.kdePackages.kwallet-pam;
  };

  # ===== Agent SSH =====
  # Retient la passphrase de ta clé après la première utilisation
  programs.ssh.startAgent = true;
  programs.ssh.extraConfig = ''
    AddKeysToAgent yes
  '';

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "fr";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "fr";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    # jack.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."wire" = {
    isNormalUser = true;
    description = "Wire";
    extraGroups = [ "networkmanager" "wheel" "i2c" "docker" ]; # i2c : luminosité des écrans externes, docker : docker sans sudo
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    gh
    git
    pciutils
    wget
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?

  # ===== GPU : Intel + NVIDIA (PRIME offload) =====
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # pour Steam et les jeux 32 bits
    # Mesa aligné sur celui de Hyprland (il est construit sur nixpkgs-unstable) :
    # sans ça, Hyprland peut refuser de démarrer sur l'iGPU Intel (versions incompatibles)
    package = hyprPkgs.mesa;
    package32 = hyprPkgs.pkgsi686Linux.mesa;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = true; # modules noyau open source, recommandés pour les RTX 40
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    powerManagement.enable = false;
    powerManagement.finegrained = true; # éteint la NVIDIA quand elle ne sert pas

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true; # fournit la commande nvidia-offload
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}
