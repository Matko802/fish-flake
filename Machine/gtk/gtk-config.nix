{ config, pkgs, ... }:

let
  amoledTheme = pkgs.callPackage ./breeze-gtk-amoled.nix {
    inherit (pkgs.kdePackages) breeze-gtk;
  };
in
{
  environment.systemPackages = [ amoledTheme ];

  environment.etc."xdg/gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=MatkosAmoled
    gtk-icon-theme-name=Papirus
    gtk-font-name=JetBrainsMono Nerd Font
    gtk-application-prefer-dark-theme=1
  '';

  environment.etc."xdg/gtk-4.0/settings.ini".text = config.environment.etc."xdg/gtk-3.0/settings.ini".text;

  environment.variables.GTK_THEME = "MatkosAmoled";

  systemd.user.services.gtk-flatpak-theme = {
    description = "Expose MatkosAmoled GTK theme to Flatpak apps";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      rm -rf "$HOME/.config/gtk-3.0/gtk.css"
      rm -rf "$HOME/.config/gtk-4.0/gtk.css"
      rm -rf "$HOME/.local/share/themes/MatkosAmoled"
      mkdir -p "$HOME/.local/share/themes"
      cp -r "${amoledTheme}/share/themes/MatkosAmoled" "$HOME/.local/share/themes/MatkosAmoled"
      chmod -R u+w "$HOME/.local/share/themes/MatkosAmoled"

      mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
      cat > "$HOME/.config/gtk-3.0/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=MatkosAmoled
gtk-icon-theme-name=Papirus
gtk-font-name=JetBrainsMono Nerd Font
gtk-application-prefer-dark-theme=1
EOF
      cp "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"

      mkdir -p "$HOME/.local/share/flatpak/overrides"
      cat > "$HOME/.local/share/flatpak/overrides/global" <<'EOF'
[Context]
filesystems=xdg-config/gtk-3.0:ro;xdg-config/gtk-4.0:ro;xdg-config/kdeglobals:ro;xdg-data/color-schemes:ro;xdg-data/themes:ro;

[Environment]
GTK_THEME=MatkosAmoled
ICON_THEME=Papirus
QT_QPA_PLATFORMTHEME=kde
EOF
    '';
  };

  programs.dconf = {
    enable = true;
    profiles.user.databases = [{
      settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          gtk-theme = "MatkosAmoled";
          icon-theme = "Papirus";
          font-name = "JetBrainsMono Nerd Font 10";
          monospace-font-name = "JetBrainsMono Nerd Font Mono 10";
        };
      };
    }];
  };
}
