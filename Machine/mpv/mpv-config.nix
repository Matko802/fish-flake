{ pkgs, ... }: {
  xdg.configFile."mpv" = {
    source = ./config;
    recursive = true;
  };
}
