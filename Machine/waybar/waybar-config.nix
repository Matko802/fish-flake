{ pkgs, ... }: {
  xdg.configFile."waybar" = {
    source = ./config;
    recursive = true;
    force = true;
  };
}
