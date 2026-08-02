{ config, pkgs, ... }: {
  systemd.tmpfiles.rules = [
    "L+ ${config.users.users.matko.home}/.config/mpv/mpv.conf - - - - ${./config/mpv.conf}"
    "L+ ${config.users.users.matko.home}/.config/mpv/scripts - - - - ${./config/scripts}"
  ];
}
