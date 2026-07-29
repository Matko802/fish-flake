{ pkgs, ... }: {
  xdg.configFile."fish/config.fish".source = ./config/config.fish;
}
