{ config, pkgs, fontName, ... }:

let
  themeName = "MatkosAmoled";

  amoledTheme = pkgs.callPackage (
    { stdenvNoCC, lib, sassc, python3, breeze-gtk }:
    stdenvNoCC.mkDerivation {
      pname = "breeze-gtk-${lib.toLower themeName}";
      version = breeze-gtk.version;

      src = breeze-gtk.src;

      nativeBuildInputs = [
        sassc
        (python3.withPackages (ps: [ ps.pycairo ]))
      ];

      colorScheme = ../KDE-Colours/config/MatkosAmoled.colors;

      buildPhase = ''
        runHook preBuild

        mkdir -p gtk2-out assets-out
        python3 src/render_assets.py \
          -c $colorScheme \
          -b $colorScheme \
          -a assets-out \
          -g gtk2-out \
          -G .
        cp -r src/gtk2/widgets gtk2-out/

        sassc -I . src/gtk3/gtk.scss gtk3.css
        sassc -I . src/gtk4/gtk.scss gtk4.css

        cat >> gtk3.css <<'EOF'
        headerbar,
        headerbar:backdrop,
        headerbar.tiled,
        headerbar.tiled:backdrop,
        headerbar.maximized,
        headerbar.maximized:backdrop {
          border-width: 0;
          border-top: none;
          border-bottom: none;
          box-shadow: none;
          background-color: #000000;
          background-image: none;
          color: #ffffff; }

        headerbar label,
        headerbar .title,
        headerbar .subtitle,
        headerbar button,
        headerbar button.flat,
        headerbar:backdrop label,
        headerbar:backdrop .title,
        headerbar:backdrop .subtitle,
        headerbar:backdrop button,
        headerbar:backdrop button.flat,
        headerbar button:hover,
        headerbar button:active,
        headerbar button:checked,
        headerbar button:backdrop {
          color: #ffffff; }
        EOF
        cat >> gtk4.css <<'EOF'
        headerbar,
        headerbar:backdrop,
        headerbar.tiled,
        headerbar.tiled:backdrop,
        headerbar.maximized,
        headerbar.maximized:backdrop {
          border-width: 0;
          border-top: none;
          border-bottom: none;
          box-shadow: none;
          background-color: #000000;
          background-image: none;
          color: #ffffff; }

        headerbar label,
        headerbar .title,
        headerbar .subtitle,
        headerbar button,
        headerbar button.flat,
        headerbar:backdrop label,
        headerbar:backdrop .title,
        headerbar:backdrop .subtitle,
        headerbar:backdrop button,
        headerbar:backdrop button.flat,
        headerbar button:hover,
        headerbar button:active,
        headerbar button:checked,
        headerbar button:backdrop {
          color: #ffffff; }
        EOF

        cat >> gtk3.css <<'EOF'
        scale highlight {
          background: linear-gradient(alpha(@theme_selected_bg_color_breeze,0.5),alpha(@theme_selected_bg_color_breeze,0.5)), linear-gradient(@theme_bg_color_breeze,@theme_bg_color_breeze);
          border: 1px solid @theme_selected_bg_color_breeze; }
        EOF
        cat >> gtk4.css <<'EOF'
        scale highlight {
          background: linear-gradient(alpha(@theme_selected_bg_color_breeze,0.5),alpha(@theme_selected_bg_color_breeze,0.5)), linear-gradient(@theme_bg_color_breeze,@theme_bg_color_breeze);
          border: 1px solid @theme_selected_bg_color_breeze; }
        EOF

        cat >> gtk3.css <<'EOF'
        switch:checked {
          background: alpha(@theme_selected_bg_color_breeze,0.333);
          border-color: @theme_selected_bg_color_breeze; }
        switch:checked slider {
          border-color: @theme_selected_bg_color_breeze; }
        EOF
        cat >> gtk4.css <<'EOF'
        switch:checked {
          background: alpha(@theme_selected_bg_color_breeze,0.333);
          border-color: @theme_selected_bg_color_breeze; }
        switch:checked slider {
          border-color: @theme_selected_bg_color_breeze; }
        EOF

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall

        mkdir -p $out/share/themes/${themeName}/{assets,gtk-2.0,gtk-3.0,gtk-4.0}
        cp -r assets-out/. $out/share/themes/${themeName}/assets/
        cp -r src/assets/. $out/share/themes/${themeName}/assets/
        cp -r gtk2-out/. $out/share/themes/${themeName}/gtk-2.0/
        cp gtk3.css $out/share/themes/${themeName}/gtk-3.0/gtk.css
        cp gtk4.css $out/share/themes/${themeName}/gtk-4.0/gtk.css
        cp $out/share/themes/${themeName}/gtk-3.0/gtk.css $out/share/themes/${themeName}/gtk-3.0/gtk-dark.css
        cp $out/share/themes/${themeName}/gtk-4.0/gtk.css $out/share/themes/${themeName}/gtk-4.0/gtk-dark.css

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
        IconTheme=Adwaita
        EOF

        runHook postInstall
      '';
    }
  ) { inherit (pkgs.kdePackages) breeze-gtk; };
in
{
  environment.systemPackages = [
    amoledTheme
    pkgs.papirus-icon-theme
  ];

  environment.etc."xdg/gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=${themeName}
    gtk-icon-theme-name=Papirus
    gtk-font-name=${fontName}
    gtk-application-prefer-dark-theme=1
  '';

  environment.etc."xdg/gtk-4.0/settings.ini".text = config.environment.etc."xdg/gtk-3.0/settings.ini".text;

  environment.variables.GTK_THEME = themeName;

  programs.dconf = {
    enable = true;
    profiles.user.databases = [{
      settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          gtk-theme = themeName;
          icon-theme = "Papirus";
          font-name = "${fontName} 10";
          monospace-font-name = "${fontName} 10";
        };
      };
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
      mkdir -p "$HOME/.local/share/themes" "$HOME/.local/share/icons" "$HOME/.local/share/flatpak/overrides"

      ln -sfn "${amoledTheme}/share/themes/${themeName}" "$HOME/.local/share/themes/${themeName}"
      ln -sfn "${pkgs.papirus-icon-theme}/share/icons/Papirus" "$HOME/.local/share/icons/Papirus"

      if [ -d "${amoledTheme}/share/themes/${themeName}/gtk-4.0" ]; then
        ln -sfn "${amoledTheme}/share/themes/${themeName}/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"
        ln -sfn "${amoledTheme}/share/themes/${themeName}/gtk-4.0/assets" "$HOME/.config/gtk-4.0/assets"
      fi

      cat > "$HOME/.local/share/flatpak/overrides/global" <<'EOF'
[Context]
filesystems=xdg-config/gtk-3.0:ro;xdg-config/gtk-4.0:ro;xdg-config/kdeglobals:ro;xdg-data/color-schemes:ro;xdg-data/themes:ro;xdg-data/icons:ro;/nix/store:ro;

[Environment]
GTK_THEME=${themeName}
ICON_THEME=Papirus
QT_QPA_PLATFORMTHEME=kde
EOF
    '';
  };
}
