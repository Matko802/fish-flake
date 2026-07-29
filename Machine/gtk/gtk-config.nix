{ pkgs, ... }: {
  xdg.configFile."gtk-3.0/gtk.css" = {
    source = ./config/gtk-3.0/gtk.css;
    force = true;
  };
  xdg.configFile."gtk-3.0/gtk-dark.css" = {
    source = ./config/gtk-3.0/gtk-dark.css;
    force = true;
  };
  xdg.configFile."gtk-4.0/gtk.css" = {
    source = ./config/gtk-4.0/gtk.css;
    force = true;
  };
  xdg.configFile."gtk-4.0/gtk-dark.css" = {
    source = ./config/gtk-4.0/gtk-dark.css;
    force = true;
  };

  gtk = {
    enable = true;
    theme.name = "adw-gtk3-dark";
    theme.package = pkgs.adw-gtk3;
    iconTheme.name = "Adwaita";
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
      icon-theme = "Adwaita";
      font-name = "JetBrainsMono Nerd Font 10";
    };
  };
}
