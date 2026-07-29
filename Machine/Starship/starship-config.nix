{ pkgs, ... }: {
  xdg.configFile."starship.toml".source = ./starship.toml;
}
