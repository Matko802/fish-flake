{ pkgs, ... }: {
  environment.etc."xdg/kdeglobals".text = ''
    [Icons]
    Theme=Papirus-Dark
  '';
}
