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
    QT_PLUGIN_PATH = "${config.home.homeDirectory}/.local/lib/qt-5.15.19/plugins:${config.home.homeDirectory}/.local/lib/qt-6/plugins";
  };

  home.packages = with pkgs; [
    libsForQt5.qt5ct
    kdePackages.qt6ct
  ];
}
