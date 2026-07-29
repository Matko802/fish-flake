{ pkgs, ... }:

{
  systemd.user.tmpfiles.rules = [
    "L+ %h/.config/fetch - - - - ${toString ./config}"
  ];
}
