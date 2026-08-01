{ pkgs, ... }: {
  xdg.configFile."qt5ct/qt5ct.conf" = {
    text = ''
      [Appearance]
      standard_dialogs=gtk3
      style=breeze
      color_scheme_path=/home/matko/.config/qt5ct/colors/MatkosAmoled.conf
      custom_palette=false

      [Fonts]
      fixed="JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"
      general="JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"
    '';
    force = true;
  };

  xdg.configFile."qt6ct/qt6ct.conf" = {
    text = ''
      [Appearance]
      standard_dialogs=gtk3
      style=breeze
      color_scheme_path=/home/matko/.config/qt6ct/colors/MatkosAmoled.conf
      custom_palette=false

      [Fonts]
      fixed="JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"
      general="JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"
    '';
    force = true;
  };

  xdg.configFile."qt5ct/colors/MatkosAmoled.conf" = {
    source = ./config/colors/MatkosAmoled.conf;
    force = true;
  };

  xdg.configFile."qt6ct/colors/MatkosAmoled.conf" = {
    source = ./config/colors/MatkosAmoled.conf;
    force = true;
  };
}