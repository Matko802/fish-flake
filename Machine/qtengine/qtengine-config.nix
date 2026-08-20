{ inputs, pkgs, fontName, ... }:

{
  imports = [ inputs.qtengine.nixosModules.default ];

  environment.systemPackages = with pkgs.kdePackages; [
    breeze
    breeze.qt5
  ];

  programs.qtengine = {
    enable = true;

    config = {
      theme = {
        colorScheme = "${../KDE-Colours/config/MatkosAmoled.colors}";
        iconTheme = "Papirus-Dark";
        style = "breeze";

        font = {
          family = fontName;
          size = 11;
          weight = -1;
        };

        fontFixed = {
          family = fontName;
          size = 11;
          weight = -1;
        };
      };

      misc = {
        singleClickActivate = false;
        menusHaveIcons = true;
        shortcutsForContextMenus = true;
      };
    };
  };
}
