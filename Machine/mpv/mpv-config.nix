{ config, ... }: {
  systemd.tmpfiles.rules = [
    "d ${config.users.users.matko.home}/.config/mpv 0755 ${config.users.users.matko.name} users -"
    "L+ ${config.users.users.matko.home}/.config/mpv/mpv.conf - - - - ${./config/mpv.conf}"
  ];
}
