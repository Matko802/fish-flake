{ config, lib, pkgs, fontName, ... }:

let
    gtkSettings = ''
      [Settings]
      gtk-theme-name=adw-gtk3-dark
      gtk-icon-theme-name=Papirus-Dark
      gtk-font-name=${fontName} 10
      gtk-cursor-theme-name=Adwaita
      gtk-cursor-theme-size=24
      gtk-application-prefer-dark-theme=1
    '';
in
{
  environment.systemPackages = with pkgs; [
    adw-gtk3
    papirus-icon-theme
    adwaita-icon-theme
    hicolor-icon-theme
    gnome-themes-extra
    gsettings-desktop-schemas
    gtk3
    gtk4
  ];

  environment.etc."xdg/gtk-3.0/settings.ini".text = gtkSettings;

  environment.etc."xdg/gtk-4.0/settings.ini".text = gtkSettings;

  environment.sessionVariables = {
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  xdg.icons.fallbackCursorThemes = [ "Adwaita" ];

  programs.dconf = {
    enable = true;
    profiles.user.databases = [{
      settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          gtk-theme = "adw-gtk3-dark";
          icon-theme = "Papirus-Dark";
          font-name = "${fontName} 10";
          monospace-font-name = "${fontName} 10";
          cursor-theme = "Adwaita";
          cursor-size = lib.gvariant.mkInt32 24;
        };
      };
      locks = [
        "/org/gnome/desktop/interface/document-font-name"
        "/org/gnome/desktop/interface/cursor-theme"
        "/org/gnome/desktop/interface/cursor-size"
      ];
    }];
  };

  systemd.user.services.gtk-flatpak-theme = {
    description = "Expose GTK theme and settings to Flatpak apps";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p "$HOME/.local/share/themes" "$HOME/.local/share/icons" "$HOME/.local/share/flatpak/overrides" "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

      ln -sfn "${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark" "$HOME/.local/share/icons/Papirus-Dark"
      ln -sfn "${pkgs.papirus-icon-theme}/share/icons/Papirus" "$HOME/.local/share/icons/Papirus"
      ln -sfn "${pkgs.adwaita-icon-theme}/share/icons/Adwaita" "$HOME/.local/share/icons/Adwaita"

      if [ -L "$HOME/.config/gtk-3.0/gtk.css" ]; then rm -f "$HOME/.config/gtk-3.0/gtk.css"; fi
      if [ -L "$HOME/.config/gtk-4.0/gtk.css" ]; then rm -f "$HOME/.config/gtk-4.0/gtk.css"; fi
      if [ -L "$HOME/.config/gtk-4.0/assets" ]; then rm -f "$HOME/.config/gtk-4.0/assets"; fi
      if [ -L "$HOME/.config/gtk-3.0/settings.ini" ]; then rm -f "$HOME/.config/gtk-3.0/settings.ini"; fi
      if [ -L "$HOME/.config/gtk-4.0/settings.ini" ]; then rm -f "$HOME/.config/gtk-4.0/settings.ini"; fi

      if [ ! -f "$HOME/.config/gtk-3.0/settings.ini" ]; then
      cat > "$HOME/.config/gtk-3.0/settings.ini" <<EOF
      [Settings]
      gtk-theme-name=adw-gtk3-dark
      gtk-icon-theme-name=Papirus-Dark
      gtk-font-name=${fontName} 10
      gtk-cursor-theme-name=Adwaita
      gtk-cursor-theme-size=24
      gtk-application-prefer-dark-theme=1
      EOF
      fi
      if [ ! -f "$HOME/.config/gtk-4.0/settings.ini" ]; then
      cp -f "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"
      fi

      cat > "$HOME/.local/share/flatpak/overrides/global" <<EOF
      [Context]
      filesystems=xdg-config/gtk-3.0:ro;xdg-config/gtk-4.0:ro;xdg-config/kdeglobals:ro;xdg-data/color-schemes:ro;xdg-data/themes:ro;xdg-data/icons:ro;/nix/store:ro;

      [Environment]
      GTK_THEME=adw-gtk3-dark
      ICON_THEME=Papirus-Dark
      QT_QPA_PLATFORMTHEME=kde
      EOF
    '';
  };

  system.activationScripts.matkosAmoledTheme = lib.stringAfter [ "etc" ] ''
    mkdir -p /usr/share/icons
    ln -sfn ${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark /usr/share/icons/Papirus-Dark
    ln -sfn ${pkgs.papirus-icon-theme}/share/icons/Papirus /usr/share/icons/Papirus
    ln -sfn ${pkgs.adwaita-icon-theme}/share/icons/Adwaita /usr/share/icons/Adwaita
  '';
  systemd.user.targets.nixos-fake-graphical-session.wantedBy = [ "default.target" ];
}
