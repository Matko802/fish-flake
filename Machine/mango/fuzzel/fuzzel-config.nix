{ config, pkgs, ... }: {
  environment.systemPackages = [ pkgs.fuzzel ];

  systemd.tmpfiles.rules = [
    "d ${config.users.users.matko.home}/.config/fuzzel 0755 ${config.users.users.matko.name} users -"
    "L+ ${config.users.users.matko.home}/.config/fuzzel/fuzzel.ini - - - - ${./fuzzel.ini}"
  ];
}
