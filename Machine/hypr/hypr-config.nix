{ pkgs, ... }: {
  xdg.configFile."hypr" = {
    source = ./config;
    recursive = true;
    force = true;
  };
}
