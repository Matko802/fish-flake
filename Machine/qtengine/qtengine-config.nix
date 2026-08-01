{ inputs, pkgs, ... }:

{
  imports = [ inputs.qtengine.nixosModules.default ];

  environment.systemPackages = with pkgs.kdePackages; [
    breeze
    breeze.qt5
    breeze-icons
  ];

  programs.qtengine = {
    enable = true;

    config = {
      theme = {
        colorScheme = "~/fish-flake/Machine/KDE-Colours/config/MatkosAmoled.colors";
        iconTheme = "breeze-dark";
        style = "breeze";

        font = {
          family = "JetBrainsMono Nerd Font";
          size = 11;
          weight = -1;
        };

        fontFixed = {
          family = "JetBrainsMono Nerd Font";
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
