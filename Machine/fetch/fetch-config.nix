{ config, pkgs, ... }: {
  systemd.tmpfiles.rules = [
    "d ${config.users.users.matko.home}/.config/fetch 0755 ${config.users.users.matko.name} users -"
    "L+ ${config.users.users.matko.home}/.config/fetch/config - - - - ${./config}"
  ];
}
