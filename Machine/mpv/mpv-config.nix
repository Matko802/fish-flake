{ config, pkgs, ... }: {
  systemd.tmpfiles.rules = [
    "d ${config.users.users.matko.home}/.config/mpv 0755 ${config.users.users.matko.name} users -"
    "L+ ${config.users.users.matko.home}/.config/mpv/mpv.conf - - - - ${./config/mpv.conf}"
    "L+ ${config.users.users.matko.home}/.config/mpv/scripts - - - - ${./config/scripts}"
  ];
}
