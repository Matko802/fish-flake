{ pkgs, ... }: {
  home.packages = [ pkgs.waybar ];
  xdg.configFile."waybar" = {
    source = ./config;
    recursive = true;
    force = true;
  };
}
