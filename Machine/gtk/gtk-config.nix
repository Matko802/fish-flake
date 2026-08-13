{ config, lib, pkgs, ... }:

let
  cfg = config.system.gtkTheme;
in {
  options.system.gtkTheme = {
    enable = lib.mkEnableOption "system-wide GTK theming";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.adw-gtk3;
      description = "GTK theme package.";
    };

    name = lib.mkOption {
      type = lib.types.str;
      default = "adw-gtk3-dark";
      description = "Theme folder name.";
    };

    colorScheme = lib.mkOption {
      type = lib.types.enum [ "default" "prefer-dark" "prefer-light" ];
      default = "prefer-dark";
      description = "Color scheme for libadwaita/GTK4.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    programs.dconf = {
      enable = true;
      profiles.user.databases = [{
        settings = {
          "org/gnome/desktop/interface" = {
            color-scheme = cfg.colorScheme;
            gtk-theme = cfg.name;
          };
        };
      }];
    };

    environment.sessionVariables = {
      GTK_THEME = cfg.name;
    };

    environment.etc = {
      "gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-theme-name=${cfg.name}
        gtk-application-prefer-dark-theme=${if cfg.colorScheme == "prefer-dark" then "1" else "0"}
      '';
      "gtk-4.0/settings.ini".text = ''
        [Settings]
        gtk-theme-name=${cfg.name}
        gtk-application-prefer-dark-theme=${if cfg.colorScheme == "prefer-dark" then "1" else "0"}
      '';
    };
  };
}