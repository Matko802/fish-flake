{ config, lib, pkgs, fontName, ... }:

let
    themeName = "MatkosAmoled";
    colorSchemePath = ../KDE-Colours/config/MatkosAmoled.colors;
    amoledTheme = pkgs.runCommand "MatkosAmoled" {
        nativeBuildInputs = [
            (pkgs.python3.withPackages (ps: [ ps.pycairo ]))
            pkgs.gnutar
            pkgs.xz
        ];
        adw = pkgs.adw-gtk3;
        src = pkgs.kdePackages.breeze-gtk.src;
        colorScheme = colorSchemePath;
    } ''
        mkdir -p $out/share/themes/${themeName}-
        cp -r ${pkgs.adw-gtk3}/share/themes/adw-gtk3-dark/. $out/share/themes/${themeName}/
        chmod -R u+w $out/share/themes/${themeName}
        python3 - "$colorScheme" > overrides.css <<'PY'
    import sys, configparser
    cp = configparser.ConfigParser()
    cp.optionxform = str
    cp.read(sys.argv[1])
    def col(sec, key):
        r, g, b = [int(x) for x in cp.get(sec, key).split(',')]
        return "#%02x%02x%02x" % (r, g, b)
    def colf(sec, key, fb):
        return col(sec, key) if cp.has_section(sec) else fb
    win_bg  = col('Colors:Window', 'BackgroundNormal')
    win_fg  = col('Colors:Window', 'ForegroundNormal')
    view_bg = col('Colors:View', 'BackgroundNormal')
    view_fg = col('Colors:View', 'ForegroundNormal')
    sel_bg  = col('Colors:Selection', 'BackgroundNormal')
    sel_fg  = col('Colors:Selection', 'ForegroundNormal')
    hdr_bg  = colf('Colors:Header', 'BackgroundNormal', win_bg)
    hdr_fg  = colf('Colors:Header', 'ForegroundNormal', win_fg)
    back_bg = "#030303"
    back_fg = "#acacac"
    border  = "#0d0d0d"
    out = []
    def d(name, val):
        out.append("@define-color %s %s;" % (name, val))
    d("window_bg_color", win_bg)
    d("window_fg_color", win_fg)
    d("view_bg_color", view_bg)
    d("view_fg_color", view_fg)
    d("headerbar_bg_color", hdr_bg)
    d("headerbar_fg_color", hdr_fg)
    d("headerbar_border_color", hdr_bg)
    d("headerbar_backdrop_color", back_bg)
    d("headerbar_shade_color", back_bg)
    d("headerbar_darker_shade_color", "#050505")
    d("dialog_bg_color", win_bg)
    d("dialog_fg_color", win_fg)
    d("popover_bg_color", win_bg)
    d("popover_fg_color", win_fg)
    d("card_bg_color", win_bg)
    d("card_fg_color", win_fg)
    d("thumbnail_bg_color", win_bg)
    d("thumbnail_fg_color", win_fg)
    d("sidebar_bg_color", win_bg)
    d("sidebar_fg_color", win_fg)
    d("sidebar_backdrop_color", back_bg)
    d("sidebar_border_color", border)
    d("sidebar_shade_color", back_bg)
    d("secondary_sidebar_bg_color", win_bg)
    d("secondary_sidebar_fg_color", win_fg)
    d("secondary_sidebar_backdrop_color", back_bg)
    d("secondary_sidebar_border_color", border)
    d("accent_bg_color", sel_bg)
    d("accent_fg_color", sel_fg)
    d("accent_color", sel_bg)
    d("shade_color", "rgba(0,0,0,0.36)")
    d("scrollbar_outline_color", "rgba(255,255,255,0.10)")
    d("theme_bg_color", win_bg)
    d("theme_fg_color", win_fg)
    d("theme_base_color", view_bg)
    d("theme_text_color", view_fg)
    d("theme_selected_bg_color", sel_bg)
    d("theme_selected_fg_color", sel_fg)
    d("theme_unfocused_bg_color", back_bg)
    d("theme_unfocused_base_color", back_bg)
    d("theme_unfocused_fg_color", back_fg)
    d("theme_unfocused_text_color", back_fg)
    d("theme_unfocused_selected_bg_color", sel_bg)
    d("theme_unfocused_selected_fg_color", sel_fg)
    print("\n\n/* MatkosAmoled overrides */\n" + "\n".join(out))
    PY

    cat >> overrides.css <<'EOF'
    * {
      border-radius: 0px;
    }
    EOF

    cat overrides.css >> $out/share/themes/${themeName}/gtk-3.0/gtk.css
    cat overrides.css >> $out/share/themes/${themeName}/gtk-4.0/gtk.css
    cp overrides.css $out/share/themes/${themeName}/user-overrides.css

    cp $out/share/themes/${themeName}/gtk-3.0/gtk.css $out/share/themes/${themeName}/gtk-3.0/gtk-dark.css
    cp $out/share/themes/${themeName}/gtk-4.0/gtk.css $out/share/themes/${themeName}/gtk-4.0/gtk-dark.css
    mkdir -p breeze-src && tar xf "$src" -C breeze-src --strip-components=1
    mkdir -p gtk2-out assets-out
    python3 breeze-src/src/render_assets.py \
      -c "$colorScheme" \
      -b "$colorScheme" \
      -a assets-out \
      -g gtk2-out
    cp -r breeze-src/src/gtk2/widgets gtk2-out/
    cp -r gtk2-out $out/share/themes/${themeName}/gtk-2.0
    cp -r assets-out $out/share/themes/${themeName}/assets

    cat > $out/share/themes/${themeName}/settings.ini <<'EOF'
    [Settings]
    gtk-error-bell=0
    EOF

    cat > $out/share/themes/${themeName}/index.theme <<'EOF'
    [Desktop Entry]
    Type=X-GNOME-Metatheme
    Name=MatkosAmoled
    Encoding=UTF-8

    [X-GNOME-Metatheme]
    GtkTheme=MatkosAmoled
    IconTheme=Papirus-Dark
    EOF
    '';
in
{
  environment.systemPackages = with pkgs; [
    amoledTheme
    papirus-icon-theme
  ];

  environment.etc."xdg/gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=${themeName}
    gtk-icon-theme-name=Papirus-Dark
    gtk-font-name=${fontName} 10
    gtk-cursor-theme-name=Adwaita
    gtk-cursor-theme-size=24
    gtk-application-prefer-dark-theme=1
  '';

  environment.etc."xdg/gtk-4.0/settings.ini".text = config.environment.etc."xdg/gtk-3.0/settings.ini".text;

  environment.variables.GTK_THEME = themeName;

  environment.sessionVariables = {
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
  };

  xdg.icons.fallbackCursorThemes = [ "Adwaita" ];

  programs.dconf = {
    enable = true;
    profiles.user.databases = [{
      settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          gtk-theme = themeName;
          icon-theme = "Papirus-Dark";
          font-name = "${fontName} 10";
          monospace-font-name = "${fontName} 10";
          cursor-theme = "Adwaita";
          cursor-size = lib.gvariant.mkInt32 24;
        };
      };
      locks = [
        "/org/gnome/desktop/interface/color-scheme"
        "/org/gnome/desktop/interface/gtk-theme"
        "/org/gnome/desktop/interface/icon-theme"
        "/org/gnome/desktop/interface/font-name"
        "/org/gnome/desktop/interface/monospace-font-name"
        "/org/gnome/desktop/interface/document-font-name"
        "/org/gnome/desktop/interface/cursor-theme"
        "/org/gnome/desktop/interface/cursor-size"
      ];
    }];
  };

  systemd.user.services.gtk-flatpak-theme = {
    description = "Expose MatkosAmoled GTK theme and settings to Flatpak apps";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p "$HOME/.local/share/themes" "$HOME/.local/share/icons" "$HOME/.local/share/flatpak/overrides" "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0" "$HOME/.local/share/color-schemes"

      ln -sfn "${amoledTheme}/share/themes/${themeName}" "$HOME/.local/share/themes/${themeName}"
      ln -sfn "${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark" "$HOME/.local/share/icons/Papirus-Dark"
      ln -sfn "${pkgs.adwaita-icon-theme}/share/icons/Adwaita" "$HOME/.local/share/icons/Adwaita"
      ln -sfn "${amoledTheme}/share/themes/${themeName}/user-overrides.css" "$HOME/.config/gtk-4.0/gtk.css"
      ln -sfn "${amoledTheme}/share/themes/${themeName}/user-overrides.css" "$HOME/.config/gtk-3.0/gtk.css"
      ln -sfn "${../KDE-Colours/config/MatkosAmoled.colors}" "$HOME/.local/share/color-schemes/MatkosAmoled.colors"

      cat > "$HOME/.local/share/flatpak/overrides/global" <<'EOF'
[Context]
filesystems=xdg-config/gtk-3.0:ro;xdg-config/gtk-4.0:ro;xdg-config/kdeglobals:ro;xdg-data/color-schemes:ro;xdg-data/themes:ro;xdg-data/icons:ro;/nix/store:ro;

[Environment]
GTK_THEME=${themeName}
ICON_THEME=Papirus-Dark
QT_QPA_PLATFORMTHEME=kde
EOF
    '';
  };

  system.activationScripts.matkosAmoledTheme = lib.stringAfter [ "etc" ] ''
    mkdir -p /usr/share/themes /usr/share/icons /usr/share/color-schemes
    ln -sfn /run/current-system/sw/share/themes/${themeName} /usr/share/themes/${themeName}
    ln -sfn ${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark /usr/share/icons/Papirus-Dark
    ln -sfn ${pkgs.adwaita-icon-theme}/share/icons/Adwaita /usr/share/icons/Adwaita
    ln -sfn ${../KDE-Colours/config/MatkosAmoled.colors} /usr/share/color-schemes/MatkosAmoled.colors
  '';
  systemd.user.targets.nixos-fake-graphical-session.wantedBy = [ "default.target" ];
}
