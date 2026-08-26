{ inputs, pkgs, fontName, lib, ... }:

{
  imports = [ inputs.qtengine.nixosModules.default ];

  environment.systemPackages = with pkgs.kdePackages; [
    breeze
    breeze.qt5
  ];

  # Steam (and any D-Bus-activated Dolphin via org.freedesktop.FileManager1)
  # inherits from systemd's show-environment, not the shell's
  # /etc/set-environment. Ensure the qtengine theme is visible to those
  # services, otherwise Dolphin launched from Steam falls back to Fusion/light.
  # Propagate the host's QT_QPA_PLATFORMTHEME (and all session vars) to the
  # systemd user manager and D-Bus activation environment.
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

  # Direct override for the D-Bus-activated Dolphin daemon
  # (org.freedesktop.FileManager1 -> plasma-dolphin.service). Even with the
  # propagation service above, ensure the env is set if dolphin starts first.
  systemd.user.services.plasma-dolphin = {
    overrideStrategy = "asDropin";
    serviceConfig.Environment = "QT_QPA_PLATFORMTHEME=qtengine";
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
