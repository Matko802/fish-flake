{ pkgs, ... }: {
  xdg.configFile."mako/config" = {
    source = ./config/config;
    force = true;
  };
}
