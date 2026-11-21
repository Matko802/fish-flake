# Declaratively ensure Flatpak apps are installed (system-wide).
# Runs as a system activation script instead of a systemd service, so there
# is no unit sitting in boot. Each app is skipped when already installed.
{ lib, pkgs, ... }:

let
  flatpak = lib.getExe pkgs.flatpak;

  remoteName = "flathub";
  remoteUrl = "https://flathub.org/repo/flathub.flatpakrepo";

  installArgs = [
    "--system"
    "--noninteractive"
    "-y"
  ];

  remoteApps = [ "org.vinegarhq.Sober" ];

  bundleApps = [
    {
      appId = "com.hypixel.HytaleLauncher";
      bundle = "/home/matko/Stiahnuté/hytale-launcher-latest.flatpak";
    }
  ];

  installRemote =
    app:
    ''
      if ! ${flatpak} info --system ${lib.escapeShellArg app} >/dev/null 2>&1; then
        ${flatpak} install ${lib.escapeShellArgs installArgs} ${remoteName} ${lib.escapeShellArg app} || true
      fi'';

  installBundle =
    { appId, bundle }:
    ''
      if [ -f ${lib.escapeShellArg bundle} ] && ! ${flatpak} info --system ${lib.escapeShellArg appId} >/dev/null 2>&1; then
        ${flatpak} install ${lib.escapeShellArgs installArgs} ${lib.escapeShellArg bundle} || true
      fi'';
in
{
  system.activationScripts.flatpakApps.text = ''
    ${flatpak} remote-add --if-not-exists ${remoteName} ${remoteUrl} >/dev/null 2>&1 || true
    ${lib.concatMapStringsSep "\n" installRemote remoteApps}
    ${lib.concatMapStringsSep "\n" installBundle bundleApps}
  '';
}
