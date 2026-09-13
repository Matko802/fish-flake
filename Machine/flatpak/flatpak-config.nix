# Declaratively ensure Flatpak apps are installed (system-wide).
# Runs as a system activation script instead of a systemd service, so there
# is no unit sitting in boot. Each app is skipped when already installed.
{ lib, pkgs, ... }:

let
  remoteName = "flathub";
  remoteUrl = "https://flathub.org/repo/flathub.flatpakrepo";

  apps = [
    "org.vinegarhq.Sober"
  ];
in
{
  system.activationScripts.flatpakApps.text = ''
    ${lib.getExe pkgs.flatpak} remote-add --if-not-exists ${remoteName} ${remoteUrl} >/dev/null 2>&1 || true
    ${lib.concatMapStringsSep "\n" (app: ''
      if ! ${lib.getExe pkgs.flatpak} info ${app} >/dev/null 2>&1; then
        ${lib.getExe pkgs.flatpak} install -y ${remoteName} ${app} || true
      fi'') apps}
  '';
}
