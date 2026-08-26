{ config, pkgs, ... }: {
  programs.mango.enable = true;

  environment.systemPackages = [ pkgs.grim pkgs.slurp ];

  systemd.tmpfiles.rules = [
    "d ${config.users.users.matko.home}/.config 0755 ${config.users.users.matko.name} users -"
    "L+ ${config.users.users.matko.home}/.config/mango - - - - ${./config}"
  ];
}
