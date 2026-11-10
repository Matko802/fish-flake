{
  lib,
  stdenv,
  makeWrapper,
  curl,
  gnutar,
  gzip,
  gnugrep,
  gnused,
  coreutils,
  patchelf,
  glibc,
}:
let
  runtimeInputs = [
    curl
    gnutar
    gzip
    gnugrep
    gnused
    coreutils
    patchelf
  ];
  loader =
    if stdenv.hostPlatform.isAarch64 then
      "${glibc}/lib/ld-linux-aarch64.so.1"
    else
      "${glibc}/lib/ld-linux-x86-64.so.2";
  wrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    "${lib.makeBinPath runtimeInputs}"
    "--set"
    "OPENCODE_NIX_LOADER"
    loader
  ];
in
stdenv.mkDerivation {
  pname = "opencode-manager";
  version = "rolling";

  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    install -Dm755 ${./opencode-manager} $out/bin/opencode-manager
    install -Dm755 ${./opencode-manager} $out/bin/opencode
    patchShebangs $out/bin/opencode-manager $out/bin/opencode
    wrapProgram $out/bin/opencode-manager ${lib.escapeShellArgs wrapperArgs} --set OPENCODE_MANAGER_MODE 1
    wrapProgram $out/bin/opencode ${lib.escapeShellArgs wrapperArgs}
    runHook postInstall
  '';

  meta = with lib; {
    description = "OpenCode launcher that installs official releases into ~/.opencode";
    license = licenses.mit;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "opencode";
  };
}
