{ pkgs, ... }: {
  home.packages = [ pkgs.hyprlock ];
  xdg.configFile."hypr/hyprlock.conf" = {
    source = ./hyprlock.conf;
    force = true;
  };
}
