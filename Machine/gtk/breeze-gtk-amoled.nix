{ stdenvNoCC, lib, sassc, python3, breeze-gtk }:

let
  themeName = "MatkosAmoled";
in
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

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/themes/${themeName}/{assets,gtk-2.0,gtk-3.0,gtk-4.0}
    cp -r assets-out/. $out/share/themes/${themeName}/assets/
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
    IconTheme=breeze-dark
    EOF

    runHook postInstall
  '';
}
