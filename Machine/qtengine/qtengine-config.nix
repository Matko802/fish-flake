{ inputs, pkgs, fontName, ... }:

{
  imports = [ inputs.qtengine.nixosModules.default ];

  environment.systemPackages = with pkgs.kdePackages; [
    breeze
    breeze.qt5
  ];

  environment.etc."xdg/kdeglobals".text = ''
    [Icons]
    Theme=Papirus-Dark

    [General]
    ColorScheme=MatkosAmoled

    [KDE]
    ColorScheme=MatkosAmoled
  '';

  systemd.user.services.qtengine-dbus-propagation = {
    description = "Propagate QT_QPA_PLATFORMTHEME to systemd/dbus for qtengine";
    wantedBy = [ "default.target" ];
    before = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd --all";
    };
  };

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
