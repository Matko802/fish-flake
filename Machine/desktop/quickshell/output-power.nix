{ pkgs }:
pkgs.stdenv.mkDerivation {
  pname = "quickshell-output-power";
  version = "1.0.0";

  src = ./output-power;

  nativeBuildInputs = [
    pkgs.cmake
    pkgs.pkg-config
    pkgs.wayland
  ];

  buildInputs = [
    pkgs.wayland
    pkgs.qt6Packages.qtbase.dev
    pkgs.qt6Packages.qtdeclarative
  ];

  dontWrapQtApps = true;

  meta = {
    description = "Native wlr-output-power-management-v1 QML plugin for Quickshell (replaces wlopm)";
  };
}