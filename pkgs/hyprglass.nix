# Effet "Liquid Glass" (verre réfracté) derrière les fenêtres, utilisé par Impasto.
# v0.11.0 : la release que le hyprpm.toml du plugin associe à Hyprland 0.56.2.
{ lib, mkHyprlandPlugin, fetchFromGitHub, wayland-scanner }:

mkHyprlandPlugin {
  pluginName = "hyprglass";
  version = "0.11.0";

  src = fetchFromGitHub {
    owner = "hyprnux";
    repo = "hyprglass";
    rev = "7fc328064c63d9fbaaac8d8204eadf85dcdeae19";
    hash = "sha256-SOdn2s/oxf5v2VYHVmQvfvRIyyV9kFNvEBpQXkLCb+s=";
  };

  nativeBuildInputs = [ wayland-scanner ];

  dontUseCmakeConfigure = true;
  enableParallelBuilding = true;
  # Sans .git dans les sources, le Makefile afficherait "dev" comme version
  makeFlags = [ "HYPRGLASS_VERSION=0.11.0" ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib
    mv hyprglass.so $out/lib/libhyprglass.so
    runHook postInstall
  '';

  meta = {
    description = "Apple-style Liquid Glass effect for Hyprland";
    homepage = "https://github.com/hyprnux/hyprglass";
    license = lib.licenses.bsd3;
  };
}
