{ pkgs, ... }: {
  home.packages = [ pkgs.mako ];
  xdg.configFile."mako/config" = {
    source = ./config/config;
    force = true;
  };
}
