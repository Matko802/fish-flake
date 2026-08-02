{ config, pkgs, ... }: {
  systemd.tmpfiles.rules = [
    "L+ ${config.users.users.matko.home}/.config/fish/config.fish - - - - ${./config/config.fish}"
  ];
}
