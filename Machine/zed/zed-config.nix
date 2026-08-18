{
  config,
  pkgs,
  ...
}: {
  systemd.tmpfiles.rules = [
    "L+ ${config.users.users.matko.home}/.config/zed - - - - ${./config}"
  ];

  environment.systemPackages = with pkgs; [
    nil
    nixfmt
    nixd
    marksman
  ];
}
