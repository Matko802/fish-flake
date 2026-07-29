{ pkgs, ... }: {
  xdg.configFile."fetch/config".source = ./config;
}
