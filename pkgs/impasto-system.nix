# Les fichiers SYSTÈME du fork Impasto (dossier system/ du repo), empaquetés :
#  - le thème SDDM "impasto" (l'écran de connexion)
#  - le thème Plymouth "impasto" (l'écran de démarrage)
#  - le script d'avatar et sa règle polkit (photo de compte, partagée entre
#    l'écran de connexion et l'écran de verrouillage)
# Sur Arch, ./setup system les copie dans /usr ; ici ils viennent de l'entrée
# "impasto" du flake (nix flake update impasto pour suivre le fork).
{ lib, stdenvNoCC, makeWrapper, coreutils, src }:

stdenvNoCC.mkDerivation {
  pname = "impasto-system";
  version = "fork";
  inherit src;

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/sddm/themes
    cp -r system/usr/share/sddm/themes/impasto $out/share/sddm/themes/

    # Écran de démarrage (Plymouth) : ses images sont lues dans ImageDir
    mkdir -p $out/share/plymouth/themes
    cp -r system/usr/share/plymouth/themes/impasto $out/share/plymouth/themes/
    substituteInPlace $out/share/plymouth/themes/impasto/impasto.plymouth \
      --replace-fail /usr/share/plymouth $out/share/plymouth

    # Lancé en root par pkexec, dont le PATH ne contient rien d'utile sur NixOS
    install -Dm755 system/usr/lib/impasto/avatar $out/libexec/impasto/avatar
    patchShebangs $out/libexec/impasto/avatar
    wrapProgram $out/libexec/impasto/avatar --set PATH ${lib.makeBinPath [ coreutils ]}

    # La règle polkit doit nommer le chemin exact que pkexec reçoit
    install -Dm644 system/usr/share/polkit-1/actions/org.impasto.avatar.policy \
      $out/share/polkit-1/actions/org.impasto.avatar.policy
    substituteInPlace $out/share/polkit-1/actions/org.impasto.avatar.policy \
      --replace-fail /usr/lib/impasto/avatar $out/libexec/impasto/avatar

    runHook postInstall
  '';

  meta = {
    description = "Impasto's login screen theme and account picture helper";
    homepage = "https://github.com/XxWirexX/impasto";
    license = lib.licenses.gpl3Only;
  };
}
