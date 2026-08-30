# Declarative Flatpak app installs (system-wide)
{ config, lib, ... }:

let
  flatpak = config.services.flatpak.package;

  apps = [
    "org.vinegarhq.Sober"
  ];
in
{

  systemd.services.flatpakInstall = lib.mkIf (apps != [ ]) {
    description = "Declaratively install Flatpak apps";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ flatpak ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${lib.getExe flatpak} remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
      ${lib.concatMapStringsSep "\n"
        (app: "${lib.getExe flatpak} install -y flathub ${app}")
        apps}
    '';
  };
}
