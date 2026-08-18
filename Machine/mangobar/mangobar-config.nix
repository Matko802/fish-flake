{ config, inputs, pkgs, ... }: {
  systemd.tmpfiles.rules = [
    "L+ ${config.users.users.matko.home}/.config/mangobar - - - - ${./config}"
  ];

  environment.systemPackages = [
    inputs.mangobar.packages.x86_64-linux.mangobar
  ];
}
