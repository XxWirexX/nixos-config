# MediaPipe (Google) : détection du visage, des gestes, détourage.
# Absent de nixpkgs : on empaquette la wheel officielle de PyPI. Elle ne dépend
# pas de la version de Python (py3-none) ; sa partie native (libmediapipe.so)
# n'a besoin que de libEGL / libGLESv2, fournis par libglvnd (libGL).
{
  lib,
  buildPythonPackage,
  fetchPypi,
  autoPatchelfHook,
  libGL,
  absl-py,
  certifi,
  numpy,
  sounddevice,
  flatbuffers,
  matplotlib,
  opencv4,
}:

buildPythonPackage rec {
  pname = "mediapipe";
  version = "1.1.1";
  format = "wheel";

  src = fetchPypi {
    inherit pname version format;
    dist = "py3";
    python = "py3";
    abi = "none";
    platform = "manylinux_2_28_x86_64";
    hash = "sha256-y7VPZBHY0lT3FR/5LL/qKUE76S+AK+RqUgzHMWMZw8w=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ libGL ];

  dependencies = [ absl-py certifi numpy sounddevice flatbuffers matplotlib opencv4 ];

  # La wheel demande opencv-contrib-python (PyPI) : opencv4 de nixpkgs fournit le même cv2
  pythonRemoveDeps = [ "opencv-contrib-python" ];
  # Contraintes ~= trop strictes pour les versions de nixpkgs
  pythonRelaxDeps = true;

  pythonImportsCheck = [ "mediapipe" ];

  meta = {
    description = "Cross-platform ML solutions for live media (prebuilt wheel)";
    homepage = "https://github.com/google-ai-edge/mediapipe";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
