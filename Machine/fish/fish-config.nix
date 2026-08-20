{ config, ... }: {
  systemd.tmpfiles.rules = [
    "d ${config.users.users.matko.home}/.config/fish 0755 ${config.users.users.matko.name} users -"
    "L+ ${config.users.users.matko.home}/.config/fish/config.fish - - - - ${./config/config.fish}"
  ];
}
