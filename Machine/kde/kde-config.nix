{ pkgs, ... }: {
  environment.etc."xdg/kdeglobals".text = ''
    [Icons]
    Theme=Papirus-Dark

    [General]
    ColorScheme=MatkosAmoled

    [KDE]
    ColorScheme=MatkosAmoled
  '';
}
