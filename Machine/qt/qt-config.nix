{ pkgs, config, ... }: {
  xdg.configFile."qt5ct/qt5ct.conf" = {
    source = ./config/qt5ct.conf;
    force = true;
  };
  xdg.configFile."qt5ct/colors/MatkosAmoled.conf" = {
    source = ./config/colors/MatkosAmoled.conf;
    force = true;
  };
  xdg.configFile."qt6ct/qt6ct.conf" = {
    source = ./config/qt6ct.conf;
    force = true;
  };
  xdg.configFile."qt6ct/colors/MatkosAmoled.conf" = {
    source = ./config/colors/MatkosAmoled.conf;
    force = true;
  };

  home.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "qt5ct";
  };

  xdg.configFile."fish/conf.d/qt_env.fish" = {
    text = ''
      if not set -q QT_QPA_PLATFORMTHEME[1]
          set -gx QT_QPA_PLATFORMTHEME qt5ct
      end
      set HM_PATH (readlink ~/.local/state/home-manager/gcroots/current-home)/home-path/lib
      if test -d "$HM_PATH/qt-5.15.19/plugins"
          if not contains "$HM_PATH/qt-5.15.19/plugins" $QT_PLUGIN_PATH
              set -gx QT_PLUGIN_PATH "$HM_PATH/qt-5.15.19/plugins" $QT_PLUGIN_PATH
              if set -q DBUS_SESSION_BUS_ADDRESS[1]
                  systemctl --user set-environment QT_PLUGIN_PATH="$QT_PLUGIN_PATH" 2>/dev/null
              end
          end
      end
      if test -d "$HM_PATH/qt-6/plugins"
          if not contains "$HM_PATH/qt-6/plugins" $QT_PLUGIN_PATH
              set -gx QT_PLUGIN_PATH "$HM_PATH/qt-6/plugins" $QT_PLUGIN_PATH
              if set -q DBUS_SESSION_BUS_ADDRESS[1]
                  systemctl --user set-environment QT_PLUGIN_PATH="$QT_PLUGIN_PATH" 2>/dev/null
              end
          end
      end
    '';
    force = true;
  };

  home.packages = with pkgs; [
    libsForQt5.qt5ct
    kdePackages.qt6ct
  ];
}
