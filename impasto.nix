# Impasto — partie UTILISATEUR (home-manager)
#
# Le fork est cloné dans ~/impasto (git clone git@github.com:XxWirexX/impasto.git ~/impasto).
#  - Le CODE (shell Quickshell + config Hyprland en Lua) est LIÉ au clone :
#    tu modifies ~/impasto, Quickshell se recharge tout seul, pas de rebuild.
#    Le shell n'écrit jamais dedans (son état va dans ~/.local/state).
#  - Les CONFIGS D'APPLIS (kitty, btop, gtk…) sont COPIÉES une seule fois si
#    absentes, comme le fait l'installeur d'Impasto : le shell les réécrit
#    quand la palette change, elles ne doivent donc pas pointer vers le repo.
{ config, pkgs, lib, ... }:

let
  repo = "${config.home.homeDirectory}/impasto";
  link = path: config.lib.file.mkOutOfStoreSymlink "${repo}/home/${path}";

  # ~/.oh-my-zsh tel que l'attend le .zshrc d'Impasto : oh-my-zsh + ses deux
  # plugins dans custom/plugins (oh-my-zsh y cherche <nom>/<nom>.plugin.zsh)
  ohMyZsh = pkgs.runCommand "oh-my-zsh-impasto" { } ''
    mkdir -p $out
    for entry in ${pkgs.oh-my-zsh}/share/oh-my-zsh/* ${pkgs.oh-my-zsh}/share/oh-my-zsh/.[!.]*; do
      [ -e "$entry" ] || continue
      [ "$(basename "$entry")" = custom ] || ln -s "$entry" $out/
    done
    mkdir -p $out/custom/themes \
      $out/custom/plugins/zsh-autosuggestions \
      $out/custom/plugins/zsh-syntax-highlighting
    echo "source ${pkgs.zsh-autosuggestions}/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" \
      > $out/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
    echo "source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
      > $out/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
  '';

  # Copiés si absents (cp -n : un fichier déjà là n'est jamais écrasé)
  seeded = [
    ".config/kitty"
    ".config/gtk-3.0"
    ".config/gtk-4.0"
    ".config/btop"
    ".config/cava"
    ".config/yazi"
    ".config/fastfetch"
    ".config/starship.toml"
    ".config/nvim"                # copié : lazy.nvim y écrit son lazy-lock.json
    ".local/share/impasto"      # profils, planche de palettes
    ".local/share/wallpapers"   # les peintures
    ".local/share/fonts"
    ".local/share/icons/hicolor"
    ".local/share/zsh"            # complétion de la commande impasto
  ];
in
{
  # ── Code : liens modifiables vers le clone ─────────────────────────────────
  xdg.configFile."quickshell".source = link ".config/quickshell";
  xdg.configFile."hypr".source = link ".config/hypr";

  # ── zsh : le .zshrc du fork, oh-my-zsh construit par Nix ────────────────────
  # Sur Arch, ./setup clone oh-my-zsh et ses deux plugins dans ~/.oh-my-zsh ;
  # ici c'est le même dossier, assemblé à partir des paquets nixpkgs.
  home.file.".zshrc".source = link ".zshrc";
  home.file.".oh-my-zsh".source = ohMyZsh;
  home.file.".zshenv".text = ''
    # oh-my-zsh est en lecture seule (Nix) : cache ailleurs, pas de mise à jour
    export ZSH_CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/oh-my-zsh"
    mkdir -p "$ZSH_CACHE_DIR/completions"
    zstyle ':omz:update' mode disabled
  '';
  # Sourcé à la fin du .zshrc d'Impasto : tes alias, communs avec bash
  home.file.".zshrc.local".text = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: "alias ${name}=${lib.escapeShellArg value}") config.home.shellAliases
  ) + "\n";

  # ── Configs d'applis : copiées une fois ────────────────────────────────────
  home.activation.impastoSeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    src="${repo}/home"
    if [ -d "$src" ]; then
      for rel in ${lib.concatStringsSep " " seeded}; do
        if [ -e "$src/$rel" ]; then
          run mkdir -p "$(dirname "$HOME/$rel")"
          run cp -rn --no-preserve=mode "$src/$rel" "$(dirname "$HOME/$rel")/"
        fi
      done

      # Thème d'icônes "impasto" minimal (comme seed() dans ./setup) :
      # sans lui, GTK retombe sur hicolor et n'affiche plus d'icônes.
      icons="$HOME/.local/share/icons/impasto"
      if [ ! -f "$icons/index.theme" ]; then
        run mkdir -p "$icons"
        if [ -z "''${DRY_RUN:-}" ]; then
          printf '%s\n' '[Icon Theme]' 'Name=impasto' 'Inherits=Papirus-Dark,Adwaita,hicolor' \
            'Example=folder' 'Directories=' > "$icons/index.theme"
        fi
      fi
      run touch "$icons/impasto.colour"
    else
      echo "impasto : clone d'abord le fork dans ${repo}" >&2
    fi
  '';

  # ── Montage auto des clés USB (Hyprland ne le fait pas tout seul) ──────────
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "auto";
  };
}
